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
  for i = 1, 32 do
    map[byte(alphabet, i)] = i - 1
  end

  -- Loop over input 5 bytes at a time
  -- a, b, c, d, e are 5 x 8-bit numbers
  -- they are encoded into 8 groups of 5-bits
  -- aaaaa aaabb bbbbb bcccc ccccd ddddd ddeee eeeee
  -- use pad if none of the bits are set.
  local function encode(str)
    local parts = {}
    local j = 1
    for i = 1, #str, 5 do
      local a, b, c, d, e = byte(str, i, i + 4)
      local points = {}
      -- aaaaa
      points[1] = rshift(a, 3)
      -- aaabb
      points[2] = bor(
        lshift(band(a, 7), 2),
        b and rshift(b, 6) or 0
      )
      if b then
        -- bbbbb
        points[3] = band(rshift(b, 1), 31)
        -- bcccc
        points[4] = bor(
          lshift(band(b, 1), 4),
          c and rshift(c, 4) or 0
        )
        if c then
          -- ccccd
          points[5] = bor(
            lshift(band(c, 15), 1),
            d and rshift(d, 7) or 0
          )
          if d then
            -- ddddd
            points[6] = band(rshift(d, 2), 31)
            -- ddeee
            points[7] = bor(
              lshift(band(d, 3), 3),
              e and rshift(e, 5) or 0
            )
            if e then
              -- eeeee
              points[8] = band(e, 31)
            end
          end
        end
      end
      local chars = {}
      for k = 1, 8 do
        chars[k] = byte(alphabet, (points[k] or 32) + 1)
      end
      parts[j] = char(unpack(chars))
      j = j + 1
    end
    return concat(parts)
  end

  -- loop over input 8 characters at a time
  -- The characters are mapped to 8 x 5-bit integers a,b,c,d,e,f,g,h
  -- They need to be reassembled into 5 x 8-bit bytes
  -- aaaaabbb bbcccccd ddddeeee efffffgg ggghhhhh
  local function decode(data)
    local parts = {}
    local j = 1
    for i = 1, #data, 8 do
      local a, b, c, d, e, f, g, h = byte(data, i, i + 7)
      local chars = {}
      b = map[b]
      if b then
        a = map[a]
        -- aaaaabbb
        chars[1] = bor(
          lshift(a, 3),
          rshift(b, 2)
        )
        d = map[d]
        if d then
          c = map[c]
          -- bbcccccd
          chars[2] = bor(
            lshift(band(b, 3), 6),
            lshift(c, 1),
            rshift(d, 4)
          )
          e = map[e]
          if e then
            -- ddddeeee
            chars[3] = bor(
              lshift(band(d, 15), 4),
              rshift(e, 1)
            )
            g = map[g]
            if g then
              f = map[f]
              -- efffffgg
              chars[4] = bor(
                lshift(band(e, 1), 7),
                lshift(f, 2),
                rshift(g, 3)
              )
              h = map[h]
              if h then
                -- ggghhhhh
                chars[5] = bor(
                  lshift(band(g, 7), 5),
                  h
                )
              end
            end
          end
        end
      end
      parts[j] = char(unpack(chars))
      j = j + 1
    end
    return concat(parts)
  end

  return {
    encode = encode,
    decode = decode,
  }
end
