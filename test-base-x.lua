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

local msg = "Hello world, let's compute some bases"
p('b2', b2.encode(msg))
p('b8', b8.encode(msg))
p('b11', b11.encode(msg))
p('b16', b16.encode(msg))
p('b32', b32.encode(msg))
p('zb32', zb32.encode(msg))
p('b36', b36.encode(msg))
p('b58', b58.encode(msg))
p('b62', b62.encode(msg))
p('b64', b64.encode(msg))
p('b66', b66.encode(msg))
p('b94', b94.encode(msg))
