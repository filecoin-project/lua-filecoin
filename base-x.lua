local ffi = require 'ffi'
local u8Array = ffi.typeof 'uint8_t[?]'

return function (alphabet)
  -- Validate and convert the alphabet
  assert(type(alphabet) == 'string', 'Expected string alphabet')
  local base = #alphabet
  assert(base > 1, 'Alphabet too short')
  assert(base < 255, 'Alphabet too long')
  alphabet = u8Array(base, alphabet)

  -- Create an inverse map for the base
  local baseMap = u8Array(256)
  for i = 0, 255 do baseMap[i] = 255 end
  for i = 0, base - 1 do
    local xc = alphabet[i]
    if baseMap[xc] ~= 255 then error(string.char(xc) .. ' is ambiguous') end
    baseMap[xc] = i
  end

  local leader = alphabet[0]
  local factor = math.log(base) / math.log(256)
  local ifactor = math.log(256) / math.log(base)

  local function encode (source)
    -- Validate and convert input string
    assert(type(source) == 'string', "Expected string")
    local sourceLength = #source
    if sourceLength == 0 then return '' end
    source = u8Array(sourceLength, source)

    -- Skip & count leading zeroes.
    local zeroes = 0
    local length = 0
    local pbegin = 0
    local pend = sourceLength
    while pbegin < pend and source[pbegin] == 0 do
      pbegin = pbegin + 1
      zeroes = zeroes + 1
    end

    -- Allocate enough space in big-endian base58 representation.
    local size = bit.tobit(((pend - pbegin) * ifactor + 1))
    local b58 = u8Array(size)

    -- Process the bytes.
    while pbegin < pend do
      local carry = source[pbegin]

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
      str[#str + 1] = string.char(alphabet[b58[it]])
      it = it + 1
    end
    return table.concat(str)
  end

  -- function decodeUnsafe (source) {
  --   if (typeof source !== 'string') throw new TypeError('Expected String')
  --   if (source.length === 0) return Buffer.alloc(0)

  --   let psz = 0

  --   // Skip leading spaces.
  --   if (source[psz] === ' ') return

  --   // Skip and count leading '1's.
  --   let zeroes = 0
  --   let length = 0
  --   while (source[psz] === LEADER) {
  --     zeroes++
  --     psz++
  --   }

  --   // Allocate enough space in big-endian base256 representation.
  --   const size = (((source.length - psz) * FACTOR) + 1) >>> 0 // log(58) / log(256), rounded up.
  --   const b256 = new Uint8Array(size)

  --   // Process the characters.
  --   while (source[psz]) {
  --     // Decode character
  --     let carry = BASE_MAP[source.charCodeAt(psz)]

  --     // Invalid character
  --     if (carry === 255) return

  --     let i = 0
  --     for (let it = size - 1; (carry !== 0 || i < length) && (it !== -1); it--, i++) {
  --       carry += (BASE * b256[it]) >>> 0
  --       b256[it] = (carry % 256) >>> 0
  --       carry = (carry / 256) >>> 0
  --     }

  --     if (carry !== 0) throw new Error('Non-zero carry')
  --     length = i
  --     psz++
  --   }

  --   // Skip trailing spaces.
  --   if (source[psz] === ' ') return

  --   // Skip leading zeroes in b256.
  --   let it = size - length
  --   while (it !== size && b256[it] === 0) {
  --     it++
  --   }

  --   const vch = Buffer.allocUnsafe(zeroes + (size - it))
  --   vch.fill(0x00, 0, zeroes)

  --   let j = zeroes
  --   while (it !== size) {
  --     vch[j++] = b256[it++]
  --   }

  --   return vch
  -- }

  -- function decode (string) {
  --   const buffer = decodeUnsafe(string)
  --   if (buffer) return buffer

  --   throw new Error('Non-base' + BASE + ' character')
  -- }

  -- return {
  --   encode: encode,
  --   decodeUnsafe: decodeUnsafe,
  --   decode: decode
  -- }
  return {
    encode = encode,
  }
end

