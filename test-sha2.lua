local p = require 'pretty-print'.prettyPrint
local sha256 = require('sha256')[256]
local sha224 = require('sha256')[224]
local sha384 = require('sha512')[384]
local sha512 = require('sha512')[512]
local hex = require 'hex'

-- local h = sha256()
-- h:init()
-- h:update(('Hello'):rep(11))
-- h:update(('World'):rep(20))
-- for i = 1, 10 do
--   h:update('More bits ' .. i)
-- end
-- p(tohex(h:digest()))
local tests = {
  { '',
    'd14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f',
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    '38b060a751ac96384cd9327eb1b1e36a21fdb71114be07434c0cc7bf63f6e1da' ..
    '274edebfe76f65fbd51ad2f14898b95b',
    'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce' ..
    '47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e' },
  { 'Hello World',
    'c4890faffdb0105d991a461e668e276685401b02eab1ef4372795047',
    'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
    '99514329186b2f6ae4a1329e7ee6c610a729636335174ac6b740f9028396fcc8' ..
    '03d0e93863a7c3d90f86beee782f4f3f',
    '2c74fd17edafd80e8447b0d46741ee243b7eb74dd2149a0ab1b9246fb30382f2' ..
    '7e853d8585719e0e67cbda0daa8f51671064615d645ae27acb15bfb1447f459b' },
  { 'Decentralize the Web for the Better of Humanity!',
    '6ee0160e8dcb0ef4dfe281694a9d2e21ca8fbac4932821523dce494a',
    '92f45f9b6e0143c200759199dd75c23efc3903338ce8e62a9b2786f6fa2cec70',
    '3a355ae3e484c49ed1ee4c3d36cb24eee1c53596972d6c427f6be2ee31abd74b' ..
    '37f1ef155c98ead957b9a3cd4b9a37c9',
    '0a23b4fafad705dd1e171c0dd9678ac3799c4e0707df0a4b5bfe4dcea319c7d9' ..
    'e2c2047d69b82a9b64e38c79b01c7b8e81354a55dacd124506d052df958036e8' },
  { '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    '43f95590b27f2afde6dd97d951f5ba4fe1d154056ec3f8ffeaea6347',
    'a8ae6e6ee929abea3afcfc5258c8ccd6f85273e0d4626d26c7279f3250f77c8e',
    '648a627ba7edae512ab128eb8e4ad9cc13c9e89da332f71fe767f1c4dd0e5c2b' ..
    'd3f83009b2855c02c7c7e488bcfc84dc',
    'ad2981aa58beca63a49b8831274b89d81766a23d7932474f03e55cf00cbe2700' ..
    '4e66fd0912aed0b3cb1afee2aa904115c89db49d6c9bad785523023a9c309561' },
  { '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef' ..
    '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    '5c515ae64e8b4b4ec314fc4160f11945b3e6850f1d10c9390026c772',
    'b320e85978db05134003a2914eebddd8d3b8726818f2e2c679e1898c721562a9',
    'f932b89b678dbdddb555807703b3e4ff99d7082cc4008d3a623f40361caa24f8' ..
    'b53f7b112ed46f027ff66ef842d2d08c',
    '451e75996b8939bc540be780b33d2e5ab20d6e2a2b89442c9bfe6b4797f6440d' ..
    'ac65c58b6aff10a2ca34c37735008d671037fa4081bf56b4ee243729fa5e768e'}
}
for i = 1, #tests do
  local message, expected224, expected256, expected384, expected512  = unpack(tests[i])
  collectgarbage()
  collectgarbage()
  print()
  p { message = message }
  print 'SHA-224'
  p { expect = expected224 }
  local actual = sha224(message)
  collectgarbage()
  collectgarbage()
  p { actual = hex.encode(actual) }
  assert(hex.decode(expected224) == actual, 'sha-224 hash mismatch')
  print 'SHA-256'
  p { expect = expected256 }
  actual = sha256(message)
  collectgarbage()
  collectgarbage()
  p { actual = hex.encode(actual) }
  assert(hex.decode(expected256) == actual, 'sha-256 hash mismatch')
  print 'SHA-384'
  p { expect = expected384 }
  actual = sha384(message)
  collectgarbage()
  collectgarbage()
  p { actual = hex.encode(actual) }
  assert(hex.decode(expected384) == actual, 'sha-384 hash mismatch')
  print 'SHA-512'
  p { expect = expected512 }
  actual = sha512(message)
  collectgarbage()
  collectgarbage()
  p { actual = hex.encode(actual) }
  assert(hex.decode(expected512) == actual, 'sha-512 hash mismatch')
end
