--[[

Related reading:

- https://wiki.openssl.org/index.php/Elliptic_Curve_Cryptography
- https://wiki.openssl.org/index.php/Elliptic_Curve_Diffie_Hellman
- https://github.com/openssl/openssl/blob/master/include/openssl/ec.h

]]

local pkey = require 'openssl/pkey'
local bignum = require 'openssl/bignum'

local NistToASN1 = {
  ['P-256'] = 'prime256v1', -- X9.62/SECG curve over a 256 bit prime field
  ['P-384'] = 'secp384r1', -- NIST/SECG curve over a 384 bit prime field
  ['P-521'] = 'secp521r1' -- NIST/SECG curve over a 521 bit prime field
}

local Exchange = {}

local keymeta = getmetatable(pkey.new{ type = "EC", curve = "prime256v1" })

function Exchange.generate(curveName)
  local asnName = assert(NistToASN1[curveName], 'Unsupported curvename')
  return pkey.new{ type = "EC", curve = asnName }
end

function Exchange.export(key)
  assert(getmetatable(key) == keymeta, "Expected pkey")
  local point = key:getParameters().pub_key
  p("export", point)
  return point:toBinary()
end

function Exchange.import(curveName, str)
  local point = bignum.fromBinary(str)
  p("import", point)
  local asnName = assert(NistToASN1[curveName], 'Unsupported curvename')
  local key = pkey.new({type="EC", curve=asnName})
  local params = key:getParameters()
  p(params)
  key:setParameters{
    priv_key = 0,
    pub_key = point,
    group = params.group
  }
  key:setPrivateKey('')
  p(key)
  p(true)
  p(key:getParameters())
  return key
end

function Exchange.exchange(key, peerkey)
  assert(getmetatable(key) == keymeta, "Expected pkey")
  assert(getmetatable(peerkey) == keymeta, "Expected pkey")

  local group = C.EC_KEY_get0_group(key)
  local fieldSize = C.EC_GROUP_get_degree(group)
  local secretLen = math.floor((fieldSize + 7) / 8)
  local secret = newBuffer(secretLen)
  local point = C.EC_KEY_get0_public_key(peerkey)
  local written = C.ECDH_compute_key(secret, secretLen, point, key, nil)
  assert(written == secretLen)
  return ffi.string(secret, secretLen)
end

function Exchange.cleanup()
  assert(bn)
  C.BN_CTX_free(bn)
  bn = nil
end

return Exchange
