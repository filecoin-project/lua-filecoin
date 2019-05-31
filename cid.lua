local Multibase = require 'multibase'
local Multihash = require 'multihash'
local codecs = require 'multicodec'
local Varint = require 'varint'
local sub = string.sub

-- For v0 CIDs, we assume base58btc encoding.
local function decodeV0(cid)
  if #cid ~= 46 or sub(cid, 1, 2) ~= 'Qm' then
    return nil, 'Not v0 CID'
  end
  local hash = Multibase.getBase('z').decode(cid)
  local multihash
  hash, multihash = Multihash.decode(hash)
  return {
    version = 0,
    multibase = 'base58btc',
    multicodec = 'dag-pb',
    multihash = multihash,
    hash = hash,
  }
end

local function decodeV1(cid, index)
  index = index or 1
  local version, multibase, multicodec, multihash, hash, bin

  bin, multibase = Multibase.decode(cid)
  version, index = Varint.decode(bin, index)
  assert(version == 1, 'Expected V1 CID')
  multicodec, index = Varint.decode(bin, index)
  hash, multihash, index = Multihash.decode(bin, index)
  return {
    version = version,
    multibase = multibase,
    multicodec = codecs[multicodec],
    multihash = multihash,
    hash = hash
  }, index
end

local function encode(obj)
  local multicodec = obj.multicodec
  if type(multicodec) == 'string' then multicodec = codecs[multicodec] end
  assert(type(multicodec) == 'number', 'Unknown multicodec');
  return Multibase.encode(table.concat{
    Varint.encode(1),
    Varint.encode(multicodec),
    obj.prehash or Multihash.encode(obj.hash, obj.multihash)
  }, obj.multibase)
end

local function decode(cid)
  return (decodeV0(cid) or decodeV1(cid))
end

local function link(data, multihash, multicodec, multibase)
  return encode {
    prehash = Multihash.hash(data, multihash or 'sha2-256'),
    multicodec = multicodec or 'raw',
    multibase = multibase or 'base58btc'
  }
end

local function link0(data)
  return Multibase.getBase('base58btc').encode(Multihash.hash(data, 'sha2-256'))
end


return {
  decode = decode,
  decodeV0 = decodeV0,
  decodeV1 = decodeV1,
  encode = encode,
  link = link,
  link0 = link0,
}