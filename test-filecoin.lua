local p = require "pretty-print".prettyPrint
local hex = require 'hex'
local filecoin = require 'filecoin'
local Address = filecoin.Address
local Block = filecoin.Block
local Message = filecoin.Message
local SignedMessage = filecoin.SignedMessage
local Cbor = require 'cbor'
local bin = Cbor.bin

Address.network = 't'

local address = Address.new()
address.protocol = 0
address.payload = 1234
p(address)
print(address)
p(Cbor.encode(address))
p(Cbor.decode(Cbor.encode(address)))
p(Address.new(Cbor.decode(Cbor.encode(address))))
-- local block = Block.new()
-- p(block)
-- p(Cbor.encode(block))
-- p(Cbor.decode(Cbor.encode(block)))
-- local message = Message.new()
-- p(message)
-- local signedMessage = SignedMessage.new()
-- p(signedMessage)

-- local messagebin = hex.decode "d82c865501fd1d0f4dfcd7e99afcb99a8326b7dc459d32c6285501b882619d46558f3d9e316d11b48dcf211327026a1875c245037e11d600666d6574686f644d706172616d73617265676f6f64"
-- p(messagebin)
-- -- local message = cbor.decode(messagebin)
-- -- p(message)
-- -- p(messagebin)
-- -- p(cbor.encode(message))

-- -- local block1 = hex.decode "d82b895501fd1d0f4dfcd7e99afcb99a8326b7dc459d32c628814a69616d617469636b6574566920616d20616e20656c656374696f6e2070726f6f6681d82a5827000171a0e40220ce25e43084e66e5a92f8c3066c00c0eb540ac2f2a173326507908da06b96f678c242bb6a1a0012d687d82a5827000171a0e40220ce25e43084e66e5a92f8c3066c00c0eb540ac2f2a173326507908da06b96f6788080"
-- -- local block = cbor.decode(block1)
-- -- local encoded = cbor.encode(block)
-- -- p(block)
-- -- p(cbor.decode(encoded))
-- -- p(block1)
-- -- p(encoded)
