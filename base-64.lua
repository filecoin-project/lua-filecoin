local bit = require 'bit'
local rshift = bit.rshift
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band
local char = string.char
local byte = string.byte
local concat = table.concat

return function (alphabet)
  -- Reverse map from character code to 6-bit integer
  local map = {}
  for i = 1, 64 do
    map[byte(alphabet, i)] = i - 1
  end

  -- Loop over input 3 bytes at a time
  -- a,b,c are 3 x 8-bit numbers
  -- they are encoded into groups of 4 x 6-bit numbers
  -- aaaaaa aabbbb bbbbcc cccccc
  local function encode(str)
    local parts = {}
    local j = 1
    for i = 1, #str, 3 do
      local a, b, c = byte(str, i, i + 2)
      local points = {}
      -- aaaaaa
      points[1] = rshift(a, 2)
      -- aabbbb
      points[2] = bor(
        lshift(band(a, 3), 4),
        b and rshift(b, 4) or 0
      )
      if b then
        -- bbbbcc
        points[3] = bor(
          lshift(band(b, 15), 2),
          c and rshift(c, 6) or 0
        )
        if c then
          -- cccccc
          points[4] = band(c, 63)
        end
      end
      local chars = {}
      for k = 1, 4 do
        chars[k] = byte(alphabet, (points[k] or 64) + 1)
      end
      parts[j] = char(unpack(chars))
      j = j + 1
    end
    return concat(parts)
  end

  -- loop over input 4 characters at a time
  -- The characters are mapped to 4 x 6-bit integers a,b,c,d
  -- They need to be reassembled into 3 x 8-bit bytes
  -- aaaaaabb bbbbcccc ccdddddd
  local function decode(data)
    local parts = {}
    local j = 1
    for i = 1, #data, 4 do
      local a, b, c, d = byte(data, i, i + 3)
      local bytes = {}
      b = map[b]
      if b then
        a = map[a]
        -- aaaaaabb
        bytes[1] = bor(
          lshift(a, 2),
          rshift(b, 4)
        )
        c = map[c]
        if c then
          -- bbbbcccc
          bytes[2] = bor(
            lshift(band(b, 15), 4),
            rshift(c, 2)
          )
          d = map[d]
          if d then
            -- ccdddddd
            bytes[3] = bor(
              lshift(band(c, 3), 6),
              d
            )
          end
        end
      end
      parts[j] = char(unpack(bytes))
      j = j + 1
    end
    return concat(parts)
  end

  return {
    encode = encode,
    decode = decode,
  }
end
