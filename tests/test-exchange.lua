local ffi = require 'ffi'
local Exchange = require 'exchange'
local generate = Exchange.generate
local import = Exchange.import
local export = Exchange.export
local free = Exchange.free
local exchange = Exchange.exchange

ffi.cdef [[
  typedef struct file_t FILE;
  FILE *fopen(const char *filename, const char *mode);
  int EC_KEY_print_fp(FILE *fp, const EC_KEY *key, int off);
]]

local stdout = ffi.C.fopen('/dev/stdout', 'w')

local function log(key)
  ffi.C.EC_KEY_print_fp(stdout, key, 2)
end

local function test(curve)
  local priv1 = generate(curve)
  local priv2 = generate(curve)
  local pub1 = import(curve, export(priv1))
  local pub2 = import(curve, export(priv2))
  p(priv1)
  log(priv1)
  p(pub2)
  log(pub2)
  local secret1 = exchange(priv1, pub2)
  p(secret1)
  p(priv2)
  log(priv2)
  p(pub1)
  log(pub1)
  local secret2 = exchange(priv2, pub1)
  p(secret2)
  assert(secret1 == secret2)
  free(priv1)
  free(priv2)
  free(pub1)
  free(pub2)
end

test('P-256')
test('P-384')
test('P-521')

Exchange.cleanup()