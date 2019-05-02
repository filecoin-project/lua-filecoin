local u8Array = require 'u8-array'
local bit = require 'bit'
local rshift = bit.rshift
local lshift = bit.lshift
local bor = bit.bor
local band = bit.band
local char = string.char
local byte = string.byte
local sub = string.sub
local find = string.find
local concat = table.concat

return function (alphabet)
  -- Reverse map from character code to 6-bit integer
  local map = {}
  for i = 1, 32 do
    map[byte(alphabet, i)] = i - 1
  end
  local pad = byte(alphabet, 33) or 0

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
      local part = char(
        -- aaaaa
        byte(alphabet, rshift(a, 3) + 1),
        -- aaabb
        byte(alphabet, bor(
          lshift(band(a, 7), 2),
          b and rshift(b, 6) or 0
        ) + 1),
        -- bbbbb
        b and byte(alphabet,
          band(rshift(b, 1), 31) + 1) or pad,
        -- bcccc
        b and byte(alphabet, bor(
          lshift(band(b, 1), 4),
          c and rshift(c, 4) or 0
        ) + 1) or pad,
        -- ccccd
        c and byte(alphabet, bor(
          lshift(band(c, 15), 1),
          d and rshift(d, 7) or 0
        ) + 1) or pad,
        -- ddddd
        d and byte(alphabet,
          band(rshift(d, 2), 31) + 1) or pad,
        -- ddeee
        d and byte(alphabet, bor(
          lshift(band(d, 3), 3),
          e and rshift(e, 5) or 0
        ) + 1) or pad,
        -- eeeee
        e and byte(alphabet,
          band(e, 31) + 1) or pad
      )
      -- trim trailing null bytes
      local i = find(part, '\0')
      if i then part = sub(part, 1, i - 1) end
      parts[j] = part
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
      a = map[a]
      b = map[b]
      c = map[c]
      d = map[d]
      e = map[e]
      f = map[f]
      g = map[g]
      h = map[h]
      local part = char(
        -- aaaaabbb
        bor(
          lshift(a, 3),
          b and rshift(b, 2) or 0
        ),
        -- bbcccccd
        b and bor(
          lshift(band(b, 3), 6),
          c and lshift(c, 1) or 0,
          d and rshift(d, 4) or 0
        ) or 0,
        -- ddddeeee
        d and bor(
          lshift(band(d, 15), 4),
          e and rshift(e, 1) or 0
        ) or 0,
        -- efffffgg
        e and bor(
          lshift(band(e, 1), 7),
          f and lshift(f, 2) or 0,
          g and rshift(g, 3) or 0
        ) or 0,
        -- ggghhhhh
        g and bor(
          lshift(band(g, 7), 5),
          h or 0
        ) or 0
      )
      local used = rshift(#{a, b, c, d, e, f, g, h} * 5, 3)
      if used < 5 then part = sub(part, 1, used) end
      parts[j] = part
      j = j + 1
    end
    return concat(parts)
  end

  return {
    encode = encode,
    decode = decode,
  }
end
