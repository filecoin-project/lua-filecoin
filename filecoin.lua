local p = require "pretty-print".prettyPrint
local cbor = require 'cbor'
require 'cid-cbor'

cbor.registerTag(43, {
  tag = 'Block',
  encode = function (obj)
    return {
      obj.Miner,
      obj.Tickets,
      obj.ElectionProof,
      obj.Parents,
      obj.ParentWeight,
      obj.Height,
      obj.StateRoot,
      obj.Messages,
      obj.MessageReceipts,
    }
  end,
  decode = function (val)
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
  end
})

cbor.registerTag(44, {
  tag = 'Message',
  encode = function (obj)
    return {
      obj.To,
      obj.From,
      obj.Nonce,
      obj.Value,
      obj.Method,
      obj.Params,
    }
  end,
  decode = function (val)
    return {
      To = val[1],
      From = val[2],
      Nonce = val[3],
      Value = val[4],
      Method = val[5],
      Params = val[6],
    }
  end
})

cbor.registerTag(45, {
  encode = function (obj)
    return {
      obj.Message,
      obj.Signature,
    }
  end,
  decode = function (val)
    return {
      Message = val[1],
      Signature = val[2],
    }
  end
})

local function hex2bin(hex)
  local parts = {}
  local j = 1
  for i = 1, #hex, 2 do
    parts[j] = string.char(tonumber(string.sub(hex, i, i + 1), 16))
    j = j + 1
  end
  return table.concat(parts)
end

-- local message = cbor.decode(
--   hex2bin"d82c865501fd1d0f4dfcd7e99afcb99a8326b7dc459d32c6285501b882619d46558f3d9e316d11b48dcf211327026a1875c245037e11d600666d6574686f644d706172616d73617265676f6f64"
-- )
-- p("Message", message)
-- p(cbor.encode(message))

local block1 = hex2bin"d82b895501fd1d0f4dfcd7e99afcb99a8326b7dc459d32c628814a69616d617469636b6574566920616d20616e20656c656374696f6e2070726f6f6681d82a5827000171a0e40220ce25e43084e66e5a92f8c3066c00c0eb540ac2f2a173326507908da06b96f678c242bb6a1a0012d687d82a5827000171a0e40220ce25e43084e66e5a92f8c3066c00c0eb540ac2f2a173326507908da06b96f6788080"
local block = cbor.decode(block1)
local encoded = cbor.encode(block)
p(block)
p(cbor.decode(encoded))
p(block1)
p(encoded)
