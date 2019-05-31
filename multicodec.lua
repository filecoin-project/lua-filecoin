local codecs = {
  [0x55] = "raw",                   -- raw binary
  [0x70] = "dag-pb",                -- MerkleDAG protobuf
  [0x71] = "dag-cbor",              -- MerkleDAG cbor
  [0x72] = "libp2p-key",            -- Libp2p Public Key
  [0x78] = "git-raw",               -- Raw Git object
  [0x7b] = "torrent-info",          -- Torrent file info field (bencoded)
  [0x7c] = "torrent-file",          -- Torrent file (bencoded)
  [0x81] = "leofcoin-block",        -- Leofcoin Block
  [0x82] = "leofcoin-tx",           -- Leofcoin Transaction
  [0x83] = "leofcoin-pr",           -- Leofcoin Peer Reputation
  [0x90] = "eth-block",             -- Ethereum Block (RLP)
  [0x91] = "eth-block-list",        -- Ethereum Block List (RLP)
  [0x92] = "eth-tx-trie",           -- Ethereum Transaction Trie (Eth-Trie)
  [0x93] = "eth-tx",                -- Ethereum Transaction (RLP)
  [0x94] = "eth-tx-receipt-trie",   -- Ethereum Transaction Receipt Trie (Eth-Trie)
  [0x95] = "eth-tx-receipt",        -- Ethereum Transaction Receipt (RLP)
  [0x96] = "eth-state-trie",        -- Ethereum State Trie (Eth-Secure-Trie)
  [0x97] = "eth-account-snapshot",  -- Ethereum Account Snapshot (RLP)
  [0x98] = "eth-storage-trie",      -- Ethereum Contract Storage Trie (Eth-Secure-Trie)
  [0xb0] = "bitcoin-block",         -- Bitcoin Block
  [0xb1] = "bitcoin-tx",            -- Bitcoin Tx
  [0xc0] = "zcash-block",           -- Zcash Block
  [0xc1] = "zcash-tx",              -- Zcash Tx
  [0xd0] = "stellar-block",         -- Stellar Block
  [0xd1] = "stellar-tx",            -- Stellar Tx
  [0xe0] = "decred-block",          -- Decred Block
  [0xe1] = "decred-tx",             -- Decred Tx
  [0xf0] = "dash-block",            -- Dash Block
  [0xf1] = "dash-tx",               -- Dash Tx
  [0xfa] = "swarm-manifest",        -- Swarm Manifest
  [0xfb] = "swarm-feed",            -- Swarm Feed
  [0x0129] = "dag-json",            -- MerkleDAG json
}
for k, n in pairs(codecs) do
  codecs[n] = k
end
return codecs