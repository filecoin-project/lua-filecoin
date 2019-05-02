local bit = require 'bit'
local band = bit.band
local rshift = bit.rshift
local sub = string.sub
local byte = string.byte
local char = string.char
local concat = table.concat

return function (alphabet)
  assert(#alphabet == 16)
  local map = {}
  for i = 0, 255 do
    local chunk = char(
      byte(alphabet, band(rshift(i, 4), 15) + 1),
      byte(alphabet, band(i, 15) + 1)
    )
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
    local missing = #encoded % 2
    if missing > 0 then encoded = sub(alphabet, 1, 1) .. encoded end
    local parts = {}
    local j = 1
    for i = 1, #encoded, 2 do
      local chunk = sub(encoded, i, i + 1)
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