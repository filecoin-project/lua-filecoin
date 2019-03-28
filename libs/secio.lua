local Protobuf = require 'protobuf'
local Msg = require 'msgframe'
local prettyPrint = require 'pretty-print'

local ssl = require 'openssl'
local pkey = ssl.pkey
local digest = ssl.digest
local hmac = ssl.hmac
local Exchange = require 'exchange'

local Connection = require 'connection'

local ffi = require 'ffi'
local C = ffi.C
ffi.cdef [[
  typedef struct file_t FILE;
  FILE *fopen(const char *filename, const char *mode);
  int EC_KEY_print_fp(FILE *fp, const EC_KEY *key, int off);
  int BIO_dump_fp(FILE *fp, const char *s, int len);
  int	BIO_dump_indent_fp(FILE *fp, const char *s, int len, int indent);

]]

local stdout = ffi.C.fopen('/dev/stdout', 'w')

local function log(key)
  C.EC_KEY_print_fp(stdout, key, 2)
end

local function dump(label, str, indent)
  indent = indent or 0
  print(string.rep(' ', indent) .. prettyPrint.colorize('highlight', label) .. ':')
  indent = indent + 2
  local typ = type(str)
  if typ == 'string' then
    C.BIO_dump_indent_fp(stdout, str, #str, indent)
  elseif typ == 'table' then
    for k, v in pairs(str) do
      dump(k, v, indent)
    end
    return
  else
    print(string.rep(' ', indent) .. prettyPrint.dump(str))
  end
end

local Secio = {}

local SupportedExchanges = 'P-256,P-384,P-521'
-- local SupportedCiphers = 'AES-256,AES-128,Blowfish'
local SupportedCiphers = 'AES-256,AES-128'
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

local function selectBest(order, set1, set2)
  if order == 0 then
    return set1:match('([^,]+)')
  end
  if order < 0 then
    set2, set1 = set1, set2
  end
  for first in set1:gmatch('([^,]+)') do
    for second in set2:gmatch('([^,]+)') do
      if first == second then
        return first
      end
    end
  end
end

-- Sanity checks for selectBest algorithm
assert(selectBest(0, 'zed', 'three,two,one') == 'zed')
assert(selectBest(1, 'one,two,three', 'three,two,one') == 'one')
assert(selectBest(-1, 'one,two,three', 'three,two,one') == 'three')
assert(selectBest(1, 'one', 'three,two,one') == 'one')
assert(selectBest(1, 'two,three', 'one,three,two') == 'two')
assert(selectBest(1, '5,4,3', '1,2,3') == '3')
assert(selectBest(-1, '5,4,3', '1,2,3') == '3')
assert(selectBest(-1, 'two,three', 'one,three,two') == 'three')
assert(selectBest(-1, 'one', 'three,two,one') == 'one')

local CipherMap = {
  ['AES-128'] = {
    ivSize = 16,
    keySize = 16
  },
  ['AES-256'] = {
    ivSize = 16,
    keySize = 32
  },
  ['Blowfish'] = {
    ivSize = 8,
    keySize = 32
  }
}

-- generate two sets of keys (stretching)
-- cipher is cipher type (AES-128, AES-256, BlowFish)
-- hash is hash type (SHA256, SHA512)
-- secret is shared secret from ECDH exchange
-- output is sets of keys
local function keyStretcher(cipherType, hashType, secret)
  local sizes = assert(CipherMap[cipherType], 'Unsupported ciphertype')
  local ivSize = sizes.ivSize
  local keySize = sizes.keySize

  local hmacKeySize = 20
  local seed = 'key expansion'
  local resultLength = 2 * (ivSize + keySize + hmacKeySize)

  local a = hmac.digest(hashType, seed, secret, true)
  local parts = {}
  local left = resultLength
  local i = 0
  while left > 0 do
    i = i + 1
    local b = hmac.digest(hashType, table.concat {a, seed}, secret, true)
    parts[i] = b
    left = left - #b
    a = hmac.digest(hashType, a, secret, true)
  end
  local result = table.concat(parts)
  local half = resultLength / 2
  return {
    result:sub(1, ivSize),
    result:sub(ivSize + keySize + 1, ivSize + keySize + hmacKeySize),
    result:sub(ivSize + 1, ivSize + keySize),
  }, {
    result:sub(half + 1, half + ivSize),
    result:sub(half + ivSize + keySize + 1, half + ivSize + keySize + hmacKeySize),
    result:sub(half + ivSize + 1, half + ivSize + keySize),
  }
end

ffi.cdef [[

  enum {
    AES_MAXNR = 14,
    AES_BLOCK_SIZE = 16,
  };

  /* This should be a hidden type, but EVP requires that the size be known */
  struct aes_key_st {
    unsigned long rd_key[4 * (AES_MAXNR + 1)];
    int rounds;
  };

  typedef struct aes_key_st AES_KEY;

  const char *AES_options(void);
  int AES_set_encrypt_key(const unsigned char *userKey, const int bits,
                          AES_KEY *key);
  int AES_set_decrypt_key(const unsigned char *userKey, const int bits,
                          AES_KEY *key);
  void AES_encrypt(const unsigned char *in, unsigned char *out,
                   const AES_KEY *key);
  void AES_decrypt(const unsigned char *in, unsigned char *out,
                   const AES_KEY *key);

  typedef void(*block128_f)(const unsigned char in[16], unsigned char out[16], const void *key);

  void CRYPTO_ctr128_encrypt (
    const unsigned char *in,
    unsigned char *out,
    size_t len,
    const void *key,
    unsigned char ivec[16],
    unsigned char ecount_buf[16],
    unsigned int *num,
    block128_f block
  );
]]

-- [4 bytes len(therest)][ cipher(data) ][ H(cipher(data)) ]
-- CTR mode AES
local function wrapStream(stream, cipherType, hashType, k1, k2)

  -- local mac1 = message => hmac.digest(hashType, message, k1.macKey)
  -- local mac2 = message => hmac.digest(hashType, message, k2.macKey)
  -- local cipher1 = aes.create()
  -- local function writeChunk(chunk)

  local function readNext()
    local frame = Msg.readFrame(stream)
    dump('frame', frame)
  end

  local ivec = ffi.new('unsigned char[16]')
  local ecountBuf = ffi.new('unsigned char[16]')
  local num = ffi.new('unsigned int[1]')
  local key = ffi.new('AES_KEY')

  local function writeChunk(chunk)
    dump('to write', chunk)
    local length = #chunk
    local out = ffi.new('unsigned char[?]', length)
    C.CRYPTO_ctr128_encrypt(chunk, out, length, k1.cipherKey, ivec, ecountBuf, num, C.AES_encrypt)
    local hash = 'TODO:HASH'
    Msg.writeFrame(ffi.string(out, length) .. hash)
  end

  local readByte, readChunk = Connection.wrapRead(readNext)

  return {
    readByte = readByte,
    readChunk = readChunk,
    writeChunk = writeChunk,
    stream = stream
  }
end

function Secio.wrap(stream)
  ----------------------------------------------------------------------------
  -- step 1. Propose -- propose cipher suite + send pubkeys + nonce
  --
  -- Generate and send Hello packet.
  -- Hello = (rand, PublicKey, Supported)

  local key1 = pkey.new('rsa', 2048)
  local proposeOut = {
    rand = ssl.random(16),
    pubkey = Protobuf.encodeTable(
      PublicKeySchema,
      {
        type = KeyEnum.RSA,
        data = key1:get_public():export('der')
      }
    ),
    exchanges = SupportedExchanges,
    ciphers = SupportedCiphers,
    hashes = SupportedHashes
  }
  dump('proposeOut', proposeOut)
  local proposeOutBytes = Protobuf.encodeTable(ProposeSchema, proposeOut)
  Msg.writeFrame(stream, proposeOutBytes)

  -- Receive and parse their Propose packet
  local proposeInBytes = Msg.readFrame(stream)
  local proposeIn = Protobuf.decodeTable(ProposeSchema, proposeInBytes)
  dump('proposeIn', proposeIn)

  --------------------------------------------------------------------------
  -- step 1.1 Identify -- get identity from their key
  local skey = Protobuf.decodeTable(PublicKeySchema, proposeIn.pubkey)
  assert(skey.type == KeyEnum.RSA, 'Expected RSA key from server')
  local key2 = assert(pkey.read(skey.data, false, 'der'))
  -- TODO: do rest of get identity...

  ----------------------------------------------------------------------------
  -- step 1.2 Selection -- select/agree on best encryption parameters

  -- to determine order, use cmp(H(remote_pubkey||local_rand), H(local_pubkey||remote_rand)).
  local oh1 = digest.digest('sha256', proposeIn.pubkey .. proposeOut.rand, true)
  local oh2 = digest.digest('sha256', proposeOut.pubkey .. proposeIn.rand, true)
  assert(oh1 ~= oh2) -- talking to self (same socket. must be reuseport + dialing self)
  local order = oh1 > oh2 and 1 or -1

  -- we use the same params for both directions (must choose same curve)
  -- WARNING: if they dont SelectBest the same way, this won't work...
  local exchange = selectBest(order, proposeOut.exchanges, proposeIn.exchanges)
  local cipher = selectBest(order, proposeOut.ciphers, proposeIn.ciphers)
  local hash = selectBest(order, proposeOut.hashes, proposeIn.hashes)

  dump(
    'config',
    {
      exchange = exchange,
      cipher = cipher,
      hash = hash
    }
  )

  ----------------------------------------------------------------------------
  -- step 2. Exchange -- exchange (signed) ephemeral keys. verify signatures.

  local e1 = Exchange.generate(exchange)
  local p1 = Exchange.export(e1)

  -- Gather corpus to sign.
  local selectionOut =
    table.concat {
    proposeOutBytes,
    proposeInBytes,
    p1
  }

  -- Encode and send Exchange packet
  local exchangeOut = {
    epubkey = p1,
    signature = key1:sign(selectionOut)
  }
  dump('exchangeOut', exchangeOut)
  Msg.writeFrame(stream, Protobuf.encodeTable(ExchangeSchema, exchangeOut))

  -- Receive and decode their Exchange packet
  local exchangeIn = Protobuf.decodeTable(ExchangeSchema, Msg.readFrame(stream))
  dump('exchangeIn', exchangeIn)

  ----------------------------------------------------------------------------
  -- step 2.1. Verify -- verify their exchange packet is good.

  local e2 = Exchange.import(exchange, exchangeIn.epubkey)
  local selectionInBytes =
    table.concat {
    proposeInBytes,
    proposeOutBytes,
    exchangeIn.epubkey
  }

  local verified = key2:verify(selectionInBytes, exchangeIn.signature)
  dump('verified', verified)
  assert(verified, 'Signature verification failed in exchange')

  ----------------------------------------------------------------------------
  -- step 2.2. Keys -- generate keys for mac + encryption

  local sharedSecret = Exchange.exchange(e1, e2)
  dump('sharedSecret', sharedSecret)

  local k1, k2 = keyStretcher(cipher, hash, sharedSecret)

  -- use random nonces to decide order.
  if order < 0 then
    k2, k1 = k1, k2
  end

  dump('k1', k1)
  dump('k2', k2)

  ----------------------------------------------------------------------------
  -- step 2.3. MAC + Cipher -- prepare MAC + cipher

  stream = wrapStream(stream, cipher, hash, k1, k2)
  dump('stream', stream)

  ----------------------------------------------------------------------------
  -- step 3. Finish -- send expected message to verify encryption works (send local nonce)

  stream.writeChunk('Hello World\n')

  -- TODO: exchange verification messages

  return stream
end

return Secio
