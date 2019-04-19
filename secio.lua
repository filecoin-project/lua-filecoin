local Protobuf = require 'protobuf'
local Msg = require 'msgframe'
local prettyPrint = require 'pretty-print'

local pkey = require 'openssl/pkey'
local digest = require 'openssl/digest'
local hmac = require 'openssl/hmac'
local rand = require 'openssl/rand'
local Exchange = require 'exchange'

local Connection = require 'connection'

-- local C = ffi.load'ssl'
-- ffi.cdef [[
-- typedef struct file_t FILE;
-- FILE *fopen(const char *filename, const char *mode);
-- int EC_KEY_print_fp(FILE *fp, const EC_KEY *key, int off);
-- int BIO_dump_fp(FILE *fp, const char *s, int len);
-- int	BIO_dump_indent_fp(FILE *fp, const char *s, int len, int indent);
--
-- ]]

--local stdout = ffi.C.fopen('/dev/stdout', 'w')

--local function log(key)
--  C.EC_KEY_print_fp(stdout, key, 2)
--end

local function dump(label, str, indent)
  indent = indent or 0
  print(string.rep(' ', indent) .. prettyPrint.colorize('highlight', label) .. ':')
  indent = indent + 2
  local typ = type(str)
  if typ == 'string' then
    p(str)--C.BIO_dump_indent_fp(stdout, str, #str, indent)
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
    iv = result:sub(1, ivSize),
    macKey = result:sub(ivSize + keySize + 1, ivSize + keySize + hmacKeySize),
    key = result:sub(ivSize + 1, ivSize + keySize)
  }, {
    iv = result:sub(half + 1, half + ivSize),
    macKey = result:sub(half + ivSize + keySize + 1, half + ivSize + keySize + hmacKeySize),
    key = result:sub(half + ivSize + 1, half + ivSize + keySize)
  }
end
--[[
ffi.cdef [[
  typedef struct evp_cipher_st EVP_CIPHER;
  typedef struct evp_cipher_ctx_st EVP_CIPHER_CTX;
  typedef struct engine_st ENGINE;

  EVP_CIPHER_CTX *EVP_CIPHER_CTX_new(void);
  int EVP_CIPHER_CTX_reset(EVP_CIPHER_CTX *ctx);
  void EVP_CIPHER_CTX_free(EVP_CIPHER_CTX *ctx);

  int EVP_EncryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type,
         ENGINE *impl, const unsigned char *key, const unsigned char *iv);
  int EVP_EncryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out,
         int *outl, const unsigned char *in, int inl);
  int EVP_EncryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *out,
         int *outl);

  int EVP_DecryptInit_ex(EVP_CIPHER_CTX *ctx, const EVP_CIPHER *type,
         ENGINE *impl, const unsigned char *key, const unsigned char *iv);
  int EVP_DecryptUpdate(EVP_CIPHER_CTX *ctx, unsigned char *out,
         int *outl, const unsigned char *in, int inl);
  int EVP_DecryptFinal_ex(EVP_CIPHER_CTX *ctx, unsigned char *outm, int *outl);


  const EVP_CIPHER *EVP_aes_128_ctr(void);
  const EVP_CIPHER *EVP_aes_256_ctr(void);

  /*
  typedef struct evp_md_st EVP_MD;

  int EVP_Digest(const void *data, size_t count,
                 unsigned char *md, unsigned int *size,
                 const EVP_MD *type, ENGINE *impl);

  const EVP_MD *EVP_sha256(void);
  const EVP_MD *EVP_sha512(void);

  unsigned char *HMAC(const EVP_MD *evp_md, const void *key, int key_len,
                      const unsigned char *d, size_t n, unsigned char *md,
                      unsigned int *md_len);
  */
]]
--]]

local function makeDigest(hashType, seed)
  -- Setup the hash
  -- local digestType
  -- local digestSize
  -- if hashType == 'SHA256' then
  --   digestType = C.EVP_sha256()
  --   digestSize = 32
  -- elseif hashType == 'SHA512' then
  --   digestType = C.EVP_sha512()
  --   digestSize = 64
  -- else
  --   error('Unsupported encryption ciphertype: ' .. hashType)
  -- end
  return function(message)
    -- dump('hashType', hashType)
    -- dump('seed', seed)
    -- dump('message', message)
    return hmac.digest(hashType, message, seed, true)
  end
end

local function makeEncrypt(cipherType, iv, key)
  -- Create and initialise the context
  local ctx = C.EVP_CIPHER_CTX_new()
  assert(ctx ~= nil)

  -- Setup the cipher
  if cipherType == 'AES-128' then
    assert(1 == C.EVP_EncryptInit_ex(ctx, C.EVP_aes_128_ctr(), nil, key, iv))
  elseif cipherType == 'AES-256' then
    assert(1 == C.EVP_EncryptInit_ex(ctx, C.EVP_aes_256_ctr(), nil, key, iv))
  else
    error('Unsupported encryption ciphertype: ' .. cipherType)
  end

  local alive = true

  return function(plainText)
    assert(alive)
    if not plainText then
      C.EVP_CIPHER_CTX_free(ctx)
      alive = false
      return
    end

    local plainLen = #plainText
    local cipherText = newBuffer(plainLen)
    local len = ffi.new 'int[1]'
    assert(1 == C.EVP_EncryptUpdate(ctx, cipherText, len, plainText, plainLen))
    return ffi.string(cipherText, len[0])
  end
end

local function makeDecrypt(cipherType, iv, key)
  -- Create and initialise the context
  local ctx = C.EVP_CIPHER_CTX_new()
  assert(ctx ~= nil)

  -- Setup the cipher
  if cipherType == 'AES-128' then
    assert(1 == C.EVP_DecryptInit_ex(ctx, C.EVP_aes_128_ctr(), nil, key, iv))
  elseif cipherType == 'AES-256' then
    assert(1 == C.EVP_EncryptInit_ex(ctx, C.EVP_aes_256_ctr(), nil, key, iv))
  else
    error('Unsupported decryption ciphertype: ' .. cipherType)
  end

  local alive = true
  return function(cipherText)
    assert(alive)
    if not cipherText then
      C.EVP_CIPHER_CTX_free(ctx)
      alive = false
      return
    end

    local cipherLen = #cipherText
    local plainText = newBuffer(cipherLen)
    local len = ffi.new 'int[1]'
    assert(1 == C.EVP_DecryptUpdate(ctx, plainText, len, cipherText, cipherLen))
    return ffi.string(plainText, len[0])
  end
end

-- [4 bytes len(therest)][ cipher(data) ][ H(cipher(data)) ]
-- CTR mode AES
local function wrapStream(stream, cipherType, hashType, k1, k2)
  local encrypt = makeEncrypt(cipherType, k1.iv, k1.key)
  local decrypt = makeDecrypt(cipherType, k2.iv, k2.key)
  local mac1 = makeDigest(hashType, k1.macKey)
  local mac2 = makeDigest(hashType, k2.macKey)
  local hashSize = hashType == 'SHA256' and 32 or 64

  local function readNext()
    local frame = Msg.readFrame(stream)
    if not frame then
      return
    end
    local length = #frame
    local cipher = frame:sub(1, length - hashSize)
    local hash = frame:sub(length - hashSize + 1, length)
    assert(mac2(cipher) == hash, 'digest mismatch')
    local chunk = decrypt(cipher)
    dump('reading', chunk)
    return chunk
  end

  local function writeChunk(chunk)
    dump('writing', chunk)
    if not chunk then
      stream.writeChunk()
      return
    end
    local encrypted = encrypt(chunk)
    local hash = mac1(encrypted)
    Msg.writeFrame(stream, encrypted .. hash)
  end

  local readByte, readChunk = Connection.wrapRead(readNext)

  return {
    readByte = readByte,
    readChunk = readChunk,
    writeChunk = writeChunk,
    socket = stream.socket
  }
end

function Secio.wrap(stream)
  ----------------------------------------------------------------------------
  -- step 1. Propose -- propose cipher suite + send pubkeys + nonce
  --
  -- Generate and send Hello packet.
  -- Hello = (rand, PublicKey, Supported)

  local key1 = pkey.new{ bits = 2048 }
  local proposeOut = {
    rand = rand.bytes(16),
    pubkey = Protobuf.encodeTable(
      PublicKeySchema,
      {
        type = KeyEnum.RSA,
        data = key1:tostring('der')
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
  local key2 = assert(pkey.new(skey.data, 'der'))
  -- TODO: do rest of get identity...

  ----------------------------------------------------------------------------
  -- step 1.2 Selection -- select/agree on best encryption parameters

  -- to determine order, use cmp(H(remote_pubkey||local_rand), H(local_pubkey||remote_rand)).
  local oh1 = digest.new('sha256')
    :update(proposeIn.pubkey)
    :final(proposeOut.rand)
  local oh2 = digest.new('sha256')
    :update(proposeOut.pubkey)
    :final(proposeIn.rand)
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
  dump('verified signature', verified)
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

  ----------------------------------------------------------------------------
  -- step 3. Finish -- send expected message to verify encryption works (send local nonce)

  -- stream.writeChunk(proposeIn.rand)
  stream.writeChunk(proposeIn.rand)
  local confirm = stream.readChunk(16)
  dump('confirm', {confirm, proposeOut.rand})
  assert(confirm == proposeOut.rand)

  -- TODO: exchange verification messages

  return stream
end

return Secio
