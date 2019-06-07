local Cid = require 'cid'
local Cbor = require 'cbor'

local CidMeta = Cid.meta
function CidMeta.encode(obj)
  return Cbor.bin(Cid.encode(obj))
end
function CidMeta.decode(bin)
    return Cid.decode(Cbor.str(bin))
end
Cbor.registerTag(42, CidMeta)
