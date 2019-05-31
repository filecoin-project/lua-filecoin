local rep = string.rep
local p = require 'pretty-print'.prettyPrint
local Multihash = require "multihash"
local hex = require 'hex'

local tests = {
  { input = '', name = 'sha1',
    multi = '1114da39a3ee5e6b4b0d3255bfef95601890afd80709',
    hash = 'da39a3ee5e6b4b0d3255bfef95601890afd80709' },
  { input = '', name = 'sha1', givenLength = 10,
    multi = '110ada39a3ee5e6b4b0d3255',
    hash = 'da39a3ee5e6b4b0d3255' },
  { input = rep('multihash', 100), name = 'sha1',
    multi = '1114c939afc3963385d36fabda338baeebe19a0edb58',
    hash = 'c939afc3963385d36fabda338baeebe19a0edb58' },
  { input = '', name = 'sha2-256',
    multi = '1220e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
    hash = 'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855' },
  { input = rep('multihash', 100), name = 'sha2-256',
    multi = '1220cc2c01cd11317f29716c27679166338d4b5eeb0de5f3692a29e24d36498abd28',
    hash = 'cc2c01cd11317f29716c27679166338d4b5eeb0de5f3692a29e24d36498abd28' },
  { input = rep('multihash', 100), name = 'sha2-256', givenLength = 20,
    multi = '1214cc2c01cd11317f29716c27679166338d4b5eeb0d',
    hash = 'cc2c01cd11317f29716c27679166338d4b5eeb0d' },
  { input = '', name = 'sha2-512',
    multi = '1340cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e',
    hash = 'cf83e1357eefb8bdf1542850d66d8007d620e4050b5715dc83f4a921d36ce9ce47d0d13c5d85f2b0ff8318d2877eec2f63b931bd47417a81a538327af927da3e' },
  { input = rep('multihash', 100), name = 'sha2-512',
    multi = '134051566967f6aaca30b43cd7528d73f5aa9c14965a5b68da695fdfa783fcd0c22280e3f858b9ea6333b29dc9d118e750902cee5055eb040b26bd8aecbfe7be412c',
    hash = '51566967f6aaca30b43cd7528d73f5aa9c14965a5b68da695fdfa783fcd0c22280e3f858b9ea6333b29dc9d118e750902cee5055eb040b26bd8aecbfe7be412c' },
  { input = rep('multihash', 100), name = 'sha2-512', givenLength = 40,
    multi = '132851566967f6aaca30b43cd7528d73f5aa9c14965a5b68da695fdfa783fcd0c22280e3f858b9ea6333',
    hash = '51566967f6aaca30b43cd7528d73f5aa9c14965a5b68da695fdfa783fcd0c22280e3f858b9ea6333' },
  { input = '', name = 'blake2b-256',
    multi = 'a0e402200e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8',
    hash = '0e5751c026e543b2e8ab2eb06099daa1d1e5df47778f7787faab45cdf12fe3a8' },
  { input = rep('multihash', 100), name = 'blake2b-256',
    multi = 'a0e402204556cf646984479710c85a8109001a89330c775e7420bea37fd4f6ddd2c35121',
    hash = '4556cf646984479710c85a8109001a89330c775e7420bea37fd4f6ddd2c35121' },
  { input = rep('multihash', 100), name = 'blake2b-256', givenLength = 20,
    multi = 'a0e402144556cf646984479710c85a8109001a89330c775e',
    hash = '4556cf646984479710c85a8109001a89330c775e' },
  { input = '', name = 'blake2b-384',
    multi = 'b0e40230b32811423377f52d7862286ee1a72ee540524380fda1724a6f25d7978c6fd3244a6caf0498812673c5e05ef583825100',
    hash = 'b32811423377f52d7862286ee1a72ee540524380fda1724a6f25d7978c6fd3244a6caf0498812673c5e05ef583825100' },
  { input = '', name = 'blake2b-224',
    multi = '9ce4021c836cc68931c2e4e3e838602eca1902591d216837bafddfe6f0c8cb07',
    hash = '836cc68931c2e4e3e838602eca1902591d216837bafddfe6f0c8cb07' },
  { input = '', name = 'blake2b-160',
    multi = '94e402143345524abf6bbe1809449224b5972c41790b6cf2',
    hash = '3345524abf6bbe1809449224b5972c41790b6cf2' },
  { input = '', name = 'blake2s-160',
    multi = 'd4e40214354c9c33f735962418bdacb9479873429c34916f',
    hash = '354c9c33f735962418bdacb9479873429c34916f' },
  { input = '', name = 'blake2s-224',
    multi = 'dce4021c1fa1291e65248b37b3433475b2a0dd63d54a11ecc4e3e034e7bc1ef4',
    hash = '1fa1291e65248b37b3433475b2a0dd63d54a11ecc4e3e034e7bc1ef4' },
}

for _, test in ipairs(tests) do
  print()
  p(test)
  local encoded, decoded, name, multi, hash
  encoded, name = Multihash.hash(test.input, test.name, test.givenLength)
  multi = hex.encode(encoded)
  p(multi)
  assert(multi == test.multi, 'multihash encoding failure')
  assert(name == test.name, 'encoding name mismatch')
  decoded, name = Multihash.decode(encoded)
  hash = hex.encode(decoded)
  p(name, hash)
  assert(hash == test.hash, 'decoding hash mismatch')
  assert(name == test.name, 'decoding name mistmatch')
  assert(Multihash.verify(test.input, encoded), "Verification failed")
  assert(not Multihash.verify(test.input .. 'x', encoded), "Inverse verification failed")
end
