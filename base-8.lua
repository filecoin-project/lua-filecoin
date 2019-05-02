local bit = require 'bit'
local rshift = bit.rshift
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band
local char = string.char
local byte = string.byte
local concat = table.concat

return function (alphabet)
  assert(type(alphabet) == 'string')
  -- Reverse map from character code to 6-bit integer
  local map = {}
  for i = 1, 8 do
    map[byte(alphabet, i)] = i - 1
  end

  -- Loop over input 3 bytes at a time
  -- a, b, c are 3 x 8-bit numbers
  -- they are encoded into 8 groups of 3-bits
  -- aaa aaa aab bbb bbb bcc ccc ccc
  -- use pad if none of the bits are set.
  local function encode(str)
    local parts = {}
    local j = 1
    for i = 1, #str, 3 do
      local a, b, c = byte(str, i, i + 2)
      local points = {}
      -- aaa
      points[1] = rshift(a, 5)
      -- aaa
      points[2] = band(rshift(a, 2), 7)
      -- aab
      points[3] = bor(
        lshift(band(a, 3), 1),
        b and rshift(b, 7) or 0
      )
      if b then
        -- bbb
        points[4] = band(rshift(b, 4), 7)
        -- bbb
        points[5] = band(rshift(b, 1), 7)
        -- bcc
        points[6] = bor(
          lshift(band(b, 1), 2),
          c and rshift(c, 6) or 0
        )
        if c then
          -- ccc
          points[7] = band(rshift(c, 3), 7)
          -- ccc
          points[8] = band(c, 7)
        end
      end
      local bytes = {}
      for k = 1, 8 do
        bytes[k] = byte(alphabet, (points[k] or 8) + 1)
      end
      parts[j] = char(unpack(bytes))
      j = j + 1
    end
    return concat(parts)
  end

  -- loop over input 8 characters at a time
  -- The characters are mapped to 8 x 3-bit integers a,b,c,d,e,f,g,h
  -- They need to be reassembled into 3 x 8-bit bytes
  -- aaabbbcc cdddeeef fggghhh
  local function decode(data)
    local parts = {}
    local j = 1
    for i = 1, #data, 8 do
      local a, b, c, d, e, f, g, h = byte(data, i, i + 7)
      local bytes = {}
      c = map[c]
      if c then
        a = map[a]
        b = map[b]
        -- aaabbbcc
        bytes[1] = bor(
          lshift(a, 5),
          lshift(b, 2),
          rshift(c, 1)
        )
        f = map[f]
        if f then
          d = map[d]
          e = map[e]
          -- cdddeeef
          bytes[2] = bor(
            lshift(band(c, 1), 7),
            lshift(d, 4),
            lshift(e, 1),
            rshift(f, 2)
          )
          h = map[h]
          if h then
            g = map[g]
            -- fggghhh
            bytes[3] = bor(
              lshift(band(f, 1), 6),
              lshift(g, 3),
              h
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
