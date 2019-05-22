local p = require "pretty-print".prettyPrint
local cbor = require "cbor"
local multibase = require 'multibase'
local multihash = require 'multihash'

local a = {
  cbor.makeTag(42, {"Hello World", name = "Tim", age = 37}),
  cbor.makeTag(55, true)
}
p(a)
local b = cbor.encode(a)
p(b)
p(multibase.encode('u', b))
p("sha1", multibase.encode('z', multihash("sha1", b)))
p("blake2b-256", multibase.encode('z', multihash("blake2b-256", b)))
p("blake2s-256", multibase.encode('z', multihash("blake2s-256", b)))
local c = cbor.decode(b)
p(c)
