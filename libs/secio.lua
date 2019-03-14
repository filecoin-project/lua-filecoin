local Protobuf = require 'protobuf'
local Msg = require 'msgframe'

local ssl = require 'openssl'
local pkey = ssl.pkey
local digest = ssl.digest

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

local function selectBest(order, p1, p2)
  local f, s
  if order < 0 then
    f = p2:gmatch('([^,]+)')
    s = p1:gmatch('([^,]+)')
  elseif order > 0 then
    f = p1:gmatch('([^,]+)')
    s = p2:gmatch('([^,]+)')
  else
    return p1:match('([^,]+)')
  end
  for fc in f do
    for sc in s do
      if fc == sc then
        return fc
      end
    end
  end
end

-- P-256 = prime256v1: X9.62/SECG curve over a 256 bit prime field
--      ?= secp256k1 : SECG curve over a 256 bit prime field
-- P-384 = secp384r1 : NIST/SECG curve over a 384 bit prime field
-- P-512 = secp521r1 : NIST/SECG curve over a 521 bit prime field

function Secio.wrap(stream)
  ----------------------------------------------------------------------------
  -- step 1. Propose -- propose cipher suite + send pubkeys + nonce
  --
  -- Generate and send Hello packet.
  -- Hello = (rand, PublicKey, Supported)

  local clientKey = pkey.new('rsa', 2048)
  local clientPropose = {
    rand = ssl.random(16),
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
  Msg.writeFrame(stream, Protobuf.encodeTable(ProposeSchema, clientPropose))

  -- Receive and parse their Propose packet
  local serverPropose = Protobuf.decodeTable(ProposeSchema, Msg.readFrame(stream))

  ----------------------------------------------------------------------------
  -- step 1.1 Identify -- get identity from their key
  local key = Protobuf.decodeTable(PublicKeySchema, serverPropose.pubkey)
  assert(key.type == KeyEnum.RSA, 'Expected RSA key from server')
  local serverKey = assert(pkey.read(key.data, false, 'der'))
  -- TODO: do rest of get identity...

  ----------------------------------------------------------------------------
  -- step 1.2 Selection -- select/agree on best encryption parameters

  -- to determine order, use cmp(H(remote_pubkey||local_rand), H(local_pubkey||remote_rand)).
  local oh1 = digest.digest('sha256', serverPropose.pubkey .. clientPropose.rand, true)
  local oh2 = digest.digest('sha256', clientPropose.pubkey .. serverPropose.rand, true)
  assert(oh1 ~= oh2) -- talking to self (same socket. must be reuseport + dialing self)
  local order = oh1 > oh2 and 1 or -1

  local curve = selectBest(order, clientPropose.exchanges, serverPropose.exchanges)
  local cipher = selectBest(order, clientPropose.ciphers, serverPropose.ciphers)
  local hash = selectBest(order, clientPropose.hashes, serverPropose.hashes)

  print('Client key')
  print(clientKey:get_public():export())
  print('server key')
  print(serverKey:export())
  p {
    curve = curve,
    cipher = cipher,
    hash = hash
  }
end

return Secio
