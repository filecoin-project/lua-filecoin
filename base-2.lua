local bit = require 'bit'
local band = bit.band
local rshift = bit.rshift
local sub = string.sub
local byte = string.byte
local char = string.char
local concat = table.concat

return function (alphabet)
  assert(#alphabet == 2)
  local zero = sub(alphabet, 1, 1)
  local one = sub(alphabet, 2, 2)
  local map = {}
  for i = 0, 255 do
    local parts = {}
    for j = 0, 7 do
      parts[8 - j] = band(rshift(i, j), 1) == 0 and zero or one
    end
    local chunk = concat(parts)
    map[i] = chunk
    map[chunk] = i
  end

  local function encode(message)
    local parts = {}
    for i = 1, #message do
      parts[i] = map[byte(message, i)]
    end
    return concat(parts)
  end

  local function decode(encoded)
    local missing = #encoded % 8
    if missing > 0 then encoded = zero:rep(8-missing) .. encoded end
    local parts = {}
    local j = 1
    for i = 1, #encoded, 8 do
      local chunk = sub(encoded, i, i + 7)
      parts[j] = char(assert(map[chunk]))
      j = j + 1
    end
    return concat(parts)
  end

  return {
    encode = encode,
    decode = decode
  }
end