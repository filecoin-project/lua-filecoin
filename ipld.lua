local p = require "pretty-print".prettyPrint
local Cbor = require "cbor"
local Cid = require "cid"
require 'cid-cbor'

local a = Cbor.encode {
  Cbor.makeTag(42, {"Hello World", name = "Tim", age = 37}),
  Cbor.makeTag(55, true)
}
p(a)
-- p("blake2b-256", Cid.link(a, "blake2b-256", "dag-cbor", "z"))
