local bit = require 'bit'
local bor = bit.bor
local band = bit.band
local lshift = bit.lshift
local rshift = bit.rshift
local byte = string.byte
local char = string.char

local Protobuf = require 'protobuf'
local Varint = require 'varint'
local ssl = require 'openssl'
local pkey = ssl.pkey

local Secio = {}

local SupportedExchanges = 'P-256,P-384,P-521'
local SupportedCiphers = 'AES-256,AES-128,Blowfish'
local SupportedHashes = 'SHA256,SHA512'

local ProposeSchema = {
  'rand',
  'pubkey',
  'exchanges',
  'ciphers',
  'hashes'
}

local ExchangeSchema = {
  'epubkey',
  'signature'
}

local PublicKeySchema = {
  'type',
  'data'
}

local PrivateKeySchema = {
  'type',
  'data'
}

local KeyEnum = {
  [0] = 'RSA',
  [1] = 'Ed25519',
  [2] = 'Secp256k1',
  [3] = 'ECDSA',
  RSA = 0,
  Ed25519 = 1,
  Secp256k1 = 2,
  ECDSA = 3
}

-- P-256 = prime256v1: X9.62/SECG curve over a 256 bit prime field
--      ?= secp256k1 : SECG curve over a 256 bit prime field
-- P-384 = secp384r1 : NIST/SECG curve over a 384 bit prime field
-- P-512 = secp521r1 : NIST/SECG curve over a 521 bit prime field

local function readUint32(data, index)
  return bor(
    lshift(byte(data, index), 24),
    lshift(byte(data, index + 1), 16),
    lshift(byte(data, index + 2), 8),
    byte(data, index + 3)
  ), index + 4
end

local function encodeUint32(length)
  return char(
    band(0xff, rshift(length, 24)),
    band(0xff, rshift(length, 16)),
    band(0xff, rshift(length, 8)),
    band(0xff, length)
  )
end

function Secio.wrap(stream)
  local clientKey = pkey.new('rsa', 2048)
  local clientRand = ssl.random(16)
  print("Client key")
  print(clientKey:get_public():export())
  local clientPropose =
    Protobuf.encodeTable(
    ProposeSchema,
    {
      rand = clientRand,
      pubkey = Protobuf.encodeTable(
        PublicKeySchema,
        {
          type = KeyEnum.RSA,
          data = clientKey:get_public():export('der')
        }
      ),
      exchanges = SupportedExchanges,
      ciphers = SupportedCiphers,
      hashes = SupportedHashes
    }
  )
  stream.writeChunk(encodeUint32(#clientPropose) .. clientPropose)

  local length = readUint32(stream.readChunk(4), 1)
  local message = stream.readChunk(length)
  local serverPropose = Protobuf.decodeTable(ProposeSchema, message)
  local key = Protobuf.decodeTable(PublicKeySchema, serverPropose.pubkey)
  assert(key.type == KeyEnum.RSA, 'Expected RSA key from server')
  local serverKey = assert(pkey.read(key.data, false, 'der'))
  print('server key')
  print(serverKey:export())
end

return Secio
