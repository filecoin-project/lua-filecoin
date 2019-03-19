local ffi = require 'ffi'
ffi.cdef [[
  typedef unsigned int BF_LONG;
  enum {
    BF_DECRYPT = 0,
    BF_ENCRYPT = 1,
    BF_ROUNDS = 16,
    BF_BLOCK = 8,
  };
  typedef struct bf_key_st {
    BF_LONG P[BF_ROUNDS + 2];
    BF_LONG S[4 * 256];
  } BF_KEY;
  void BF_set_key(BF_KEY *key, int len, const unsigned char *data);
  void BF_ecb_encrypt(const unsigned char *in, unsigned char *out,
      BF_KEY *key, int enc);
  void BF_cbc_encrypt(const unsigned char *in, unsigned char *out,
      long length, BF_KEY *schedule, unsigned char *ivec, int enc);
  void BF_cfb64_encrypt(const unsigned char *in, unsigned char *out,
      long length, BF_KEY *schedule, unsigned char *ivec, int *num,
      int enc);
  void BF_ofb64_encrypt(const unsigned char *in, unsigned char *out,
      long length, BF_KEY *schedule, unsigned char *ivec, int *num);
  const char *BF_options(void);
  void BF_encrypt(BF_LONG *data,const BF_KEY *key);
  void BF_decrypt(BF_LONG *data,const BF_KEY *key);
]]
local BfKey = ffi.typeof('BF_KEY')

local Blowfish = {}

function Blowfish.encryptStream()
end

return Blowfish
