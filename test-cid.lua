local p = require'pretty-print'.prettyPrint
local Cid = require 'cid'
require 'cid-cbor'
local Cbor = require 'cbor'

p(Cid)
p(Cid.decode('zb2rhe5P4gXftAwvA4eXQ5HJwsER2owDyS9sKaQRRVQPn93bA'))
p(Cid.decode('QmPZ9gcCEpqKTo6aq61g2nXGUhM4iCL3ewB6LDXZCtioEB'))
p(Cid.link0('Hello World\n'))
p(Cid.link0(''))
p(Cid.decode(Cid.encode(Cid.link0(''))))
p(Cid.link('Hello World\n'))
p(Cid.link(''))
p(Cid.decode(Cid.encode(Cid.link(''))))
p(Cid.link('{}', {multihash = 'sha2-256', multicodec = 'dag-json', multibase = 'z'}))

local link = Cid.link('', {multihash='blake2b-256'})
p(link)
local serialized = Cbor.encode(link)
p(serialized)
local deserialized = Cbor.decode(serialized)
p(deserialized)