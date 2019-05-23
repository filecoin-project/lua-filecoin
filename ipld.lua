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
p("sha1", multibase.encode('f', multihash("sha1", b)))
p("sha2-256", multibase.encode('f', multihash("sha2-256", b)))
p("sha2-512", multibase.encode('f', multihash("sha2-512", b)))
p("blake2b-256", multibase.encode('f', multihash("blake2b-256", b)))
p("blake2s-256", multibase.encode('f', multihash("blake2s-256", b)))
p("blake2b-32", multibase.encode('f', multihash("blake2b-32", b)))
p("blake2s-32", multibase.encode('f', multihash("blake2s-32", b)))
p("blake2b-512", multibase.encode('f', multihash("blake2b-512", b)))
local c = cbor.decode(b)
p(c)
