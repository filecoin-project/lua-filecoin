local Cid = require 'cid'
local Cbor = require 'cbor'
local ffi = require 'ffi'
local p = require 'pretty-print'.prettyPrint

Cbor.registerTag(42, {
  tag = "CID",
  encode = function (obj)
    return Cbor.bin(Cid.encode(obj))
  end,
  decode = function (bin)
    return Cid.decode(ffi.string(bin, ffi.sizeof(bin)))
  end
})
