local sha256 = require('sha256')[256]
local sha224 = require('sha256')[224]
local hex = require('base-16')('0123456789abcdef')

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
    'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    'd14a028c2a3a2bc9476102bb288234c415a2b01f828ea62ac5b3e42f' },
  { 'Hello World',
    'a591a6d40bf420404a011733cfb7b190d62c65bf0bcda32b57b277d9ad9f146e',
    'c4890faffdb0105d991a461e668e276685401b02eab1ef4372795047' },
  { 'Decentralize the Web for the Better of Humanity!',
    '92f45f9b6e0143c200759199dd75c23efc3903338ce8e62a9b2786f6fa2cec70',
    '6ee0160e8dcb0ef4dfe281694a9d2e21ca8fbac4932821523dce494a' },
  { '0123456789abcdef0123456789abcdef0123456789abcdef0123456789abcdef',
    'a8ae6e6ee929abea3afcfc5258c8ccd6f85273e0d4626d26c7279f3250f77c8e',
    '43f95590b27f2afde6dd97d951f5ba4fe1d154056ec3f8ffeaea6347' }
}
for i = 1, #tests do
  local message, expected256, expected224 = table.unpack(tests[i])
  print()
  p { message = message }
  print 'SHA-256'
  p { expect = expected256 }
  local actual = sha256(message)
  p { actual = hex.encode(actual) }
  assert(hex.decode(expected256) == actual, 'sha-256 hash mismatch')
  print 'SHA-224'
  p { expect = expected224 }
  actual = sha224(message)
  p { actual = hex.encode(actual) }
  assert(hex.decode(expected224) == actual, 'sha-224 hash mismatch')
end
