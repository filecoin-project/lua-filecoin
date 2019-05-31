## Multihash

There is a basic implementation of multihash here as seen in [multihash.lua](multihash.lua) and [test-multihash.lua](test-multihash.lua).

Currently this supports the following multihash types: `identity`, `sha`, `sha2-256`, `sha2-512`, `blake2b-*` (8-512), and `blake2s-*` (8-256).

Usage sample:

```lua
local Multihash = require 'multihash'

-- Multihash.encode(input, hash-name, [length-override]) -> multihash, hash-name
local multihash = Multihash.encode('Hello World', 'blake2b-256')

-- Multihash.decode(multihash, [index]) -> hash, hash-name, index
local hash, name = Multihash.decode(multihash)

-- Multihash.verify(input, multihash, [index]) -> verified, index
assert(Multihash.verify('Hello World', multihash), 'Multihash mismatch')
```

The actual implementations of the hash functions are hand-written in lua using luajit's bit and ffi libraries.  See [sha256.lua](sha256.lua), [sha512.lua](sha512.lua), [sha1.lua](sha1.lua), [blake2b.lua](blake2b.lua), and [blake2s.lua](blake2s.lua) for details.  The main module lazy requires these so only hashes actually used at runtime are ever loaded and compiled.

## Multibase

There is a basic implementation of multibase here as seen in [multibase.lua](multibase.lua) and [test-multibase.lua](test-multibase.lua).

Currently this supports the following multibase encodings: `identity`, `base2`, `base8`, `base10`, `base16`, `base16upper`, `base32`, `base32upper`, `base32pad`, `base32padupper`, `base32hex`, `base32hexupper`, `base32hexpad`, `base32hexpadupper`, `base32z`, `base58flickr`, `base58btc`, `base64`, `base64pad`, `base64url`, and `base64urlpad`.

Usage sample:

```lua
local Multibase = require 'multibase'

-- Multibase.encode(raw, name-or-code) -> encoded, name
local encoded = Multibase.encode('Hello World', 'hex')

-- Multibase.decode(encoded) -> raw, name
local original = Multibase.decode(encoded)
```

The actual implementations of the base functions are hand-written in lua using luajit's bit and ffi libraries.  See [base-2.lua](base-2.lua), [base-8.lua](base-8.lua), [base-16.lua](base-16.lua), [base-32.lua](base-32.lua), [base-64.lua](base-64.lua), and [base-x.lua](base-x.lua) for details.  The main module lazy requires these so only bases actually used at runtime are ever loaded and compiled.