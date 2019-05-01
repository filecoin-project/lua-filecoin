local char = string.char
local byte = string.byte
local sub = string.sub

return function (alphabet)
  -- Validate and convert the alphabet
  assert(type(alphabet) == 'string', 'Expected string alphabet')
  local base = #alphabet
  assert(base > 1, 'Alphabet too short')
  assert(base <= 256, 'Alphabet too long')

  -- Create an inverse map for the base
  local baseMap = {}
  for i = 1, base do
    local xc = byte(alphabet, i)
    if baseMap[xc] then error(char(xc) .. ' is ambiguous') end
    baseMap[xc] = i
  end

  local leader = alphabet:sub(1,1)
  local factor = math.log(base) / math.log(256)
  local ifactor = math.log(256) / math.log(base)

  local function encode (source)
    -- Validate and convert input string
    assert(type(source) == 'string', "Expected string")
    local sourceLength = #source
    if sourceLength == 0 then return '' end

    -- Skip & count leading zeroes.
    local zeroes = 0
    local length = 0
    local pbegin = 1
    local pend = sourceLength
    while pbegin <= pend and byte(source, pbegin) == 0 do
      pbegin = pbegin + 1
      zeroes = zeroes + 1
    end

    local b58 = {}

    -- Process the bytes.
    while pbegin <= pend do
      local carry = byte(source, pbegin)
      p("CARRY", carry)

      -- Apply "b58 = b58 * 256 + ch".
      local i = 0
      local it = 0

      while carry > 0 or i < length do
        p(b58)
        carry = carry + 256 * (b58[it] or 0)
        b58[it] = carry % base
        carry = (carry - b58[it]) / base
        it = it - 1
        i = i + 1
      end
      assert(carry == 0, 'Non-zero carry')
      length = i
      pbegin = pbegin + 1
    end

    -- Skip leading zeroes in base58 result.
    local it = length
    while b58[it] and b58[it] == 0 do
      it = it + 1
    end

    -- Translate the result into a string.
    local str = { string.rep(leader, zeroes) }
    while it < size do
      local i = b58[it] or 0
      str[#str + 1] = sub(alphabet, i, i)
      it = it + 1
    end
    return table.concat(str)
  end

  local function decode(source)
    -- Validate and convert the source
    assert(type(source) == 'string', 'Expected string alphabet')
    local sourceLength = #source
    if sourceLength == 0 then return "" end
    source = u8Array(sourceLength, source)

    local psz = 0

    -- Skip and count leading '1's.
    local zeroes = 0
    local length = 0
    while source[psz] == leader do
      zeroes = zeroes + 1
      psz = psz + 1
    end

    -- Allocate enough space in big-endian base256 representation.
    local size = bit.tobit(((sourceLength - psz) * factor) + 1) 
    local b256 = u8Array(size)

    -- Process the characters.
    while source[psz] > 0 do
      -- Decode character
      local carry = baseMap[source[psz]]

      assert(carry < 255, "Invalid Character")

      local i = 0
      local it = size - 1
      while (carry ~= 0 or i < length) and it ~= -1 do
        carry = carry + (base * b256[it])
        b256[it] = (carry % 256)
        carry = bit.rshift(carry, 8)
        it = it - 1
        i = i + 1
      end

      assert(carry == 0, "Non-zero carry")
      length = i
      psz = psz + 1
    end

    -- Skip leading zeroes in b256.
    local it = size - length
    while it ~= size and b256[it] == 0 do
      it = it + 1
    end

    local vch = u8Array(zeroes + (size - it))

    local j = zeroes
    -- TODO: optimize with ffi memcopy
    while it ~= size do
      vch[j] = b256[it]
      j = j + 1
      it = it + 1
    end

    return ffi.string(vch, j)
  end

  return {
    encode = encode,
    decode = decode,
  }
end

