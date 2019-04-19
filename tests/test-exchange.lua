dofile 'pretty-print.lua'
local Exchange = require 'exchange'
local generate = Exchange.generate
local import = Exchange.import
local export = Exchange.export
local free = Exchange.free
local exchange = Exchange.exchange

local function test(curve)
  local priv1 = generate(curve)
  local priv2 = generate(curve)
  local pub1 = import(curve, export(priv1))
  local pub2 = import(curve, export(priv2))
  p(priv1)
  p(pub2)
  local secret1 = exchange(priv1, pub2)
  p(secret1)
  p(priv2)
  p(pub1)
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