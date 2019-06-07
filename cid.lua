local Multibase = require 'multibase'
local Multihash = require 'multihash'
local codecs = require 'multicodec'
local Varint = require 'varint'
local sub = string.sub

local CidMeta = { tag = "CID" }

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

local function encodeV0(obj)
  if obj.version then assert(obj.version == 0) end
  if obj.multibase then assert(obj.multibase == "base58btc" or obj.multibase == "z") end
  if obj.multicodec then assert(obj.multicodec == "dag-pb" or obj.multicodec == 0x70) end
  if obj.multihash then assert(obj.multihash == "sha2-256" or obj.multihash == 0x12) end
  assert(obj.hash and #obj.hash == 32)
  return Multibase.getBase('base58btc').encode(Multihash.encode(obj.hash, "sha2-256"))
end

local function encodeV1(obj)
  if obj.version then assert(obj.version == 1) end
  assert(obj.hash and obj.multihash)
  local multicodec = obj.multicodec or "raw"
  if type(multicodec) == 'string' then multicodec = codecs[multicodec] end
  assert(type(multicodec) == 'number', 'Unknown multicodec');

  return Multibase.encode(table.concat{
    Varint.encode(1),
    Varint.encode(multicodec),
    Multihash.encode(obj.hash, obj.multihash)
  }, obj.multibase or "base58btc")
end

local function encode(obj)
  if obj.version == 0 then return encodeV0(obj) end
  if obj.version == 1 then return encodeV1(obj) end
  if obj.version == 1 then
    local multicodec = obj.multicodec
    if type(multicodec) == 'string' then multicodec = codecs[multicodec] end
    assert(type(multicodec) == 'number', 'Unknown multicodec');
      return Multibase.encode(table.concat{
      Varint.encode(1),
      Varint.encode(multicodec),
      Multihash.encode(obj.hash, obj.multihash)
    }, obj.multibase)
  end
  error("Unknown CID version " .. obj.version)
end

local function decode(cid)
  return (decodeV0(cid) or decodeV1(cid))
end

local function link(data, options)
  options = options or {}
  local multihash = options.multihash or "blake2b-256"
  return setmetatable({
    version = 1,
    multicodec = options.multicodec or 'raw',
    multibase = options.multibase or 'base58btc',
    multihash = multihash,
    hash = Multihash.getHash(multihash)(data)
  }, CidMeta)
end

local function link0(data)
  local multihash = 'sha2-256'
  return setmetatable({
    version = 0,
    multibase = 'base58btc',
    multicodec = 'dag-pb',
    multihash = multihash,
    hash = Multihash.getHash(multihash)(data)
  }, CidMeta)
end


return {
  meta = CidMeta,
  decode = decode,
  decodeV0 = decodeV0,
  decodeV1 = decodeV1,
  encode = encode,
  encodeV0 = encodeV0,
  encodeV1 = encodeV1,
  link = link,
  link0 = link0,
}