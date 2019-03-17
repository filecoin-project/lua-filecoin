--[[

Related reading:

- https://wiki.openssl.org/index.php/Elliptic_Curve_Cryptography
- https://wiki.openssl.org/index.php/Elliptic_Curve_Diffie_Hellman
- https://github.com/openssl/openssl/blob/master/include/openssl/ec.h

]]
local ffi = require 'ffi'
local newBuffer = require 'buffer'

ffi.cdef [[
  typedef struct ec_key_st EC_KEY;
  typedef struct ec_group_st EC_GROUP;
  typedef struct ec_point_st EC_POINT;
  typedef struct bignum_ctx BN_CTX;
  typedef enum {
    POINT_CONVERSION_COMPRESSED = 2,
    POINT_CONVERSION_UNCOMPRESSED = 4,
    POINT_CONVERSION_HYBRID = 6
  } point_conversion_form_t;
  void BN_CTX_free(BN_CTX *c);
  BN_CTX *BN_CTX_new(void);
  int EC_GROUP_get_degree(const EC_GROUP *group);
  int EC_KEY_check_key(const EC_KEY *key);
  int EC_KEY_generate_key(EC_KEY *key);
  const EC_GROUP *EC_KEY_get0_group(const EC_KEY *key);
  const EC_POINT *EC_KEY_get0_public_key(const EC_KEY *key);
  EC_KEY *EC_KEY_new_by_curve_name(int nid);
  int EC_KEY_set_public_key(EC_KEY *key, const EC_POINT *pub);
  void EC_POINT_free(EC_POINT *point);
  EC_POINT *EC_POINT_new(const EC_GROUP *group);
  int EC_POINT_oct2point(const EC_GROUP *group, EC_POINT *p, const unsigned char *buf, size_t len, BN_CTX *ctx);
  size_t EC_POINT_point2oct(const EC_GROUP *group, const EC_POINT *p,
    point_conversion_form_t form,
    unsigned char *buf, size_t len, BN_CTX *ctx);
  int ECDH_compute_key(void *out, size_t outlen, const EC_POINT *pub_key,
    const EC_KEY *ecdh,
    void *(*KDF) (const void *in, size_t inlen,
      void *out, size_t *outlen));
  void EC_KEY_free(EC_KEY *key);
  int OBJ_sn2nid(const char *s);
]]

local NistToASN1 = {
  ['P-256'] = 'prime256v1', -- X9.62/SECG curve over a 256 bit prime field
  ['P-384'] = 'secp384r1', -- NIST/SECG curve over a 384 bit prime field
  ['P-521'] = 'secp521r1' -- NIST/SECG curve over a 521 bit prime field
}

local NistToNid = {}
local function getNid(curveName)
  local nid = NistToNid[curveName]
  if not nid then
    local asnName = assert(NistToASN1[curveName], 'Unsupported curvename')
    nid = ffi.C.OBJ_sn2nid(asnName)
    NistToNid[curveName] = nid
  end
  return nid
end

local bn = ffi.C.BN_CTX_new()

local Exchange = {}

function Exchange.generate(curveName)
  local key = ffi.C.EC_KEY_new_by_curve_name(getNid(curveName))
  assert(ffi.C.EC_KEY_generate_key(key) == 1)
  return key
end

function Exchange.export(key)
  assert(ffi.C.EC_KEY_check_key(key) == 1)
  local group = ffi.C.EC_KEY_get0_group(key)
  local point = ffi.C.EC_KEY_get0_public_key(key)
  -- TODO: find if we can derive this size value from the group.
  local buf = newBuffer(133)
  local size =
    ffi.C.EC_POINT_point2oct(
    group,
    point,
    ffi.C.POINT_CONVERSION_UNCOMPRESSED,
    buf,
    ffi.sizeof(buf),
    bn
  )
  return ffi.string(buf, size)
end

function Exchange.import(curveName, str)
  local key = assert(ffi.C.EC_KEY_new_by_curve_name(getNid(curveName)))
  local group = assert(ffi.C.EC_KEY_get0_group(key))
  local point = assert(ffi.C.EC_POINT_new(group))
  ffi.C.EC_POINT_oct2point(group, point, str, #str, bn)
  ffi.C.EC_KEY_set_public_key(key, point)
  ffi.C.EC_POINT_free(point) -- TODO: os this safe?
  return key
end

function Exchange.free(key)
  assert(ffi.C.EC_KEY_check_key(key) == 1)
  ffi.C.EC_KEY_free(key)
end

function Exchange.exchange(key, peerkey)
  assert(ffi.C.EC_KEY_check_key(key) == 1)
  assert(ffi.C.EC_KEY_check_key(peerkey) == 1)
  local group = ffi.C.EC_KEY_get0_group(key)
  local fieldSize = ffi.C.EC_GROUP_get_degree(group)
  local secretLen = math.floor((fieldSize + 7) / 8)
  local secret = newBuffer(secretLen)
  local point = ffi.C.EC_KEY_get0_public_key(peerkey)
  local written = ffi.C.ECDH_compute_key(secret, secretLen, point, key, nil)
  assert(written == secretLen)
  return ffi.string(secret, secretLen)
end

function Exchange.cleanup()
  assert(bn)
  ffi.C.BN_CTX_free(bn)
  bn = nil
end

return Exchange