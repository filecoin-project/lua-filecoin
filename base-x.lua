local ffi = require 'ffi'
local u8Array = ffi.typeof 'uint8_t[?]'
local byte = string.byte
local sub = string.sub

return function (alphabet)
  -- Validate and convert the alphabet
  assert(type(alphabet) == 'string', 'Expected string alphabet')
  local base = #alphabet
  assert(base > 1, 'Alphabet too short')
  assert(base < 255, 'Alphabet too long')

  -- Create an inverse map for the base
  local baseMap = u8Array(256)
  for i = 0, 255 do baseMap[i] = 255 end
  for i = 1, base do
    local xc = byte(alphabet, i)
    if baseMap[xc] ~= 255 then error(string.char(xc) .. ' is ambiguous') end
    baseMap[xc] = i - 1
  end

  local leader = byte(alphabet, 1)
  local factor = math.log(base) / math.log(256)
  local ifactor = math.log(256) / math.log(base)

  local function encode (source)
    -- Validate input string
    assert(type(source) == 'string', "Expected string")
    local sourceLength = #source
    if sourceLength == 0 then return '' end

    -- Skip & count leading zeroes.
    local zeroes = 0
    local length = 0
    local pbegin = 0
    local pend = sourceLength
    while pbegin < pend and byte(source, pbegin + 1) == 0 do
      pbegin = pbegin + 1
      zeroes = zeroes + 1
    end

    -- Allocate enough space in big-endian base58 representation.
    local size = bit.tobit(((pend - pbegin) * ifactor + 1))
    local b58 = u8Array(size)

    -- Process the bytes.
    while pbegin < pend do
      local carry = byte(source, pbegin + 1)

      -- Apply "b58 = b58 * 256 + ch".
      local i = 0
      local it = size - 1
      while (carry > 0 or i < length) and it >= 0 do
        carry = carry + 256 * b58[it]
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
    local it = size - length
    while it ~= size and b58[it] == 0 do
      it = it + 1
    end

    -- Translate the result into a string.
    local str = {string.rep(string.char(leader), zeroes) }
    while it < size do
      local idx = b58[it] + 1
      str[#str + 1] = sub(alphabet, idx, idx)
      it = it + 1
    end
    return table.concat(str)
  end

  local function decode(source)
    -- Validate the source
    assert(type(source) == 'string', 'Expected string alphabet')
    local sourceLength = #source
    if sourceLength == 0 then return "" end

    local psz = 0

    -- Skip and count leading '1's.
    local zeroes = 0
    local length = 0
    while byte(source, psz + 1) == leader do
      zeroes = zeroes + 1
      psz = psz + 1
    end

    -- Allocate enough space in big-endian base256 representation.
    local size = bit.tobit(((sourceLength - psz) * factor) + 1)
    local b256 = u8Array(size)

    -- Process the characters.
    while byte(source, psz + 1) or 0 > 0 do
      -- Decode character
      local carry = baseMap[byte(source, psz + 1)]

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

