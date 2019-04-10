local ffi = require 'ffi'
local cbor = require 'cbor'
local registerTag = cbor.registerTag
local decode = cbor.decode



registerTag(2, function (val)
  -- TODO: do something with this?
  p("Bigint", val, ffi.string(val, ffi.sizeof(val)))
  return val
end)

registerTag(42, function (val)
  -- TODO: should we represent cid in some other way?
  p("CID", val, ffi.string(val, ffi.sizeof(val)))
  return val
end)

registerTag(43, function (val)
  return {
    Miner = val[1],
    Tickets = val[2],
    ElectionProof = val[3],
    Parents = val[4],
    ParentWeight = val[5],
    Height = val[6],
    StateRoot = val[7],
    Messages = val[8],
    MessageReceipts = val[9],
  }
end)

registerTag(44, function (val)
  return {
    To = val[1],
    From = val[2],
    Nonce = val[3],
    Value = val[4],
    Method = val[5],
    Params = val[6],
  }
end)

registerTag(45, function (val)
  return {
    Message = val[1],
    Signature = val[2],
  }
end)

local function hex2bin(hex)
  local parts = {}
  local j = 1
  for i = 1, #hex, 2 do
    parts[j] = string.char(tonumber(string.sub(hex, i, i + 1), 16))
    j = j + 1
  end
  return table.concat(parts)
end

p(decode(
  hex2bin"d82c865501fd1d0f4dfcd7e99afcb99a8326b7dc459d32c6285501b882619d46558f3d9e316d11b48dcf211327026a1875c245037e11d600666d6574686f644d706172616d73617265676f6f64"
))
p(decode(
  hex2bin"d82b895501fd1d0f4dfcd7e99afcb99a8326b7dc459d32c628814a69616d617469636b6574566920616d20616e20656c656374696f6e2070726f6f6681d82a5827000171a0e40220ce25e43084e66e5a92f8c3066c00c0eb540ac2f2a173326507908da06b96f678c242bb6a1a0012d687d82a5827000171a0e40220ce25e43084e66e5a92f8c3066c00c0eb540ac2f2a173326507908da06b96f6788080"
))
