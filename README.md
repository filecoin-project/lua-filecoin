## Multihash

There is a basic implementation of multihash here as seen in [multihash.lua](multihash.lua) and [test-multihash.lua](test-multihash.lua).

Currently this supports the following multihash types: `identity`, `sha`, `sha2-256`, `sha2-512`, `blake2b-*` (8-512), and `blake2s-*` (8-256).

Usage sample:

```lua
local Multihash = require 'multihash'

-- Multihash.encode(input, hash-name, [length-override]) -> multihash, hash-name, actual-length
local multihash = Multihash.encode('Hello World', 'blake2b-256')

-- Multihash.decode(multihash) -> hash, hash-name, actual-length
local hash, name, length = Multihash.decode(multihash)
```

The actual implementations of the hash functions are hand-written in lua using luajit's bit and ffi libraries.  See [sha256.lua](sha256.lua), [sha512.lua](sha512.lua), [sha1.lua](sha1.lua), [blake2b.lua](blake2b.lua), and [blake2s.lua](blake2s.lua) for details.  The main module lazy requires these so only hashes actually used as runtime are ever loaded and compiled.

## Multibase

