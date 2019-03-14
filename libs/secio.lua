local Protobuf = require 'protobuf'
local Msg = require 'msgframe'

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

function Secio.wrap(stream)
  local clientKey = pkey.new('rsa', 2048)
  local clientRand = ssl.random(16)
  Msg.writeFrame(
    stream,
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
  )

  local serverPropose = Protobuf.decodeTable(ProposeSchema, Msg.readFrame(stream))
  local key = Protobuf.decodeTable(PublicKeySchema, serverPropose.pubkey)
  assert(key.type == KeyEnum.RSA, 'Expected RSA key from server')
  local serverKey = assert(pkey.read(key.data, false, 'der'))
  local serverRand = serverPropose.rand

  print('Client key')
  print(clientKey:get_public():export())
  print('server key')
  print(serverKey:export())
end

return Secio
