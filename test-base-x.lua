local baseX = require './base-x'

local b2 = baseX "01"
local b8 = baseX "01234567"
local b11 = baseX "0123456789a"
local b16 = baseX "0123456789abcdef"
local b32 = baseX "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
local zb32 = baseX "ybndrfg8ejkmcpqxot1uwisza345h769"
local b36 = baseX "0123456789abcdefghijklmnopqrstuvwxyz"
local b58 = baseX "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
local b62 = baseX "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
local b64 = baseX "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/"
local b66 = baseX "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_.!~"
local b94 = baseX '!"#$%&\'()*+,-./0123456789:;<=>?@ABCDEFGHIJKLMNOPQRSTUVWXYZ[\\]^_`abcdefghijklmnopqrstuvwxyz{|}~'

local function test(name, base)
  print("Testing " .. name)
  local msg = "Hello world, let's compute some bases"
  local encoded = base.encode(msg)
  print(encoded)
  local decoded = base.decode(encoded)
  assert(msg == decoded, "roundtrip failed")
end

test('b2', b2)
test('b8', b8)
test('b11', b11)
test('b16', b16)
test('b32', b32)
test('zb32', zb32)
test('b36', b36)
test('b58', b58)
test('b62', b62)
test('b64', b64)
test('b66', b66)
test('b94', b94)
