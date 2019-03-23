The multistream docs are out of date https://github.com/multiformats/multistream-select

When first connecting, the server sends a varint framed message with `/multistream/1.0.0\n`

We respond with `/multistream/1.0.0\n` and then request `/plaintext/1.0.0\n` and it confirms or rejects.

Then for some reason it sends `/multistream/1.0.0\n` again?

Now how do we create a mplex stream?  Does `/plaintext/1.0.0` assume mplex without encryption or do we need to do something else?  Also is the mplex with it's own length header tunneled inside framed messages or replace the framed multistream messages?

----------------------------------------
## Multistream and Mplex

multistream negotiation is used in several places.  Once to choose plaintext or encryption, again to choose mplex, and then again inside the tunneled mplex streams I think

The TCP stream requires you to negotiate either plaintext or secio, depending on how the peer is configured. (default with ipfs-go is secio)

So, for example to speak plaintext mplex, the conversation looks something like the following (each message is framed with a varint length header)

- negotiate plaintxt
  - Send: `/multistream/1.0.0\n`
  - Expect: `/multistream/1.0.0\n`
  - Send: `/plaintext/1.0.0\n`
  - Expect: `/plaintext/1.0.0\n`
- negotiate mplex 
  - Send: `/multistream/1.0.0\n`
  - Expect: `/multistream/1.0.0\n`
  - Send: `/mplex/6.7.0\n`
  - Expect: `/mplex/6.7.0\n`

After this point, the TCP socket is raw mplex messages.  These have a slightly different framing:

Each Message is framed with `varint header`, `varint length`, `message` Where the header contains the flag as the lower 3 bits and the stream ID for the rest of the bits.

## Encryption with Secio

Notice that there was nothing to do between selecting plaintext and selecting mplex.  Things are a little more complicated with encryption (aka secio).

It starts the same, but selecting `secio/1.0.0` instead of `plaintext/1.0.0`

- negotiate secio
  - Send: `/multistream/1.0.0\n`
  - Expect: `/multistream/1.0.0\n`
  - Send: `/secio/1.0.0\n`
  - Expect: `/secio/1.0.0\n`

But then we need to perform the secio handshake on this transport.  It's similar to TLS except there are no root authorities and certificates.

During secio handshake, framing is no longer using varint headers.  Instead it's using simply `uint32_t` length headers (in network byte order) for framing messages.  The messages themselves are protobufs, sometimes nested.

### Step 1 - Propose cipher suite + send pubkeys + nonce

In secio, there are three different configuration parameters that both parties need to negotiate.  They are:

- ECDH algorithms for key exchange, `P-256`, `P-384`, and `P-521` are common. These are their NIST curvenames.  Typically in openssl, you'll need to know their ASN1 OIDs `prime256v1`, `secp384r1` and `secp521r1`. I want to see if I can add `Curve25519` as well.
- Cipher to use for actual encryption.  Common options are `AES-256`, `AES-128` and `Blowfish`.  I want to add something `Gimli` based.
- hash used for MAC, common hash algorithms are `SHA256` and `SHA512`.  I want to also use `Gimli` for this.
- Each peer needs to also us a public key for signing part of the handshake and optionally authenticating itself.  This key tends to be `RSA-2048`. I want to use `ED25519` for faster ephermeral key generation.

*Basically, I want to be able to write embedded clients using https://github.com/jedisct1/libhydrogen which is why I want newer options added.*

The propose [message is a protobuf](https://github.com/libp2p/go-libp2p-secio/blob/master/pb/spipe.proto) with [another embedded inside](https://github.com/libp2p/go-libp2p-crypto/blob/master/pb/crypto.proto).

- `rand` - 16 random bytes. (Used later for tie breaking in suite resolving algorithm and for extra entropy)
- `pubkey` Which itself is protobuf encoded sub-object:
  - `type` - enum for type (typically `KeyEnum.RSA`)
  - `data` - RSA key encoded as binary der
- `exchanges` - Comma separated options like `P-256,P-384,P-521`
- `ciphers` - Comma separated options like `AES-256,AES-128,Blowfish`
- `hashes` - Comma separated options like `SHA256,SHA512`

Here are the relevent protobuf definitions:

```protobuf
message Propose {
	optional bytes rand = 1;
	optional bytes pubkey = 2;
	optional string exchanges = 3;
	optional string ciphers = 4;
	optional string hashes = 5;
}

enum KeyType {
	RSA = 0;
	Ed25519 = 1;
	Secp256k1 = 2;
	ECDSA = 3;
}

message PublicKey {
	required KeyType Type = 1;
	required bytes Data = 2;
}
```


The order is chosen based on a hash of the 16 random bytes and the public key.  This makes it hard for a peer to have priority and is essentially a deterministic random leader.

The public key of the peer (still in binary format) concated with our own random bytes (binary) runs through SHA256.  The same is done for the other side (our public key and their random bits)

These two hashes are then compared to know the order when choosing the best option

```lua
order = SHA256(inProp.key + outProp.rand) > SHA256(outProp.key, inProp.rand)
```

if `order` is true then own proposals have priority, otherwise, peer's proposals go in the outer loop.


### Step 2 - Perform ECDH exchange and verify signatures

Once you know the

### Step 3 - Send expected messages to verify encryption is working.


## Annotated Conversation

Sometimes seeing the actual bytes in an example is the best way to understand.

```sh
# 19 is varint length header
out> [13] '/multistream/1.0.0\n'
# 13 is varint length header
out> [0d] '/secio/1.0.0\n'
# Peer sends back same messages if it agrees
in> [13] '/multistream/1.0.0\n'
in> [0d] '/secio/1.0.0\n'
# Send length header for propose message
out> [00 00 01 6c] # 364 encoded as network order U32 for length header framing.
# See https://developers.google.com/protocol-buffers/docs/encoding for protobuf parts
# rand is 16 random bytes
     00001 010 # Field 1 type length-delimited (1 byte varint and then result is split into bits)
     0 0010000 # varint for length (16 bytes)
     [7c 90 e1 67 8c f0 5e cd 63 fc db 8b 34 e8 1f f5] # 16 random bytes
# pubkey is nested inline protobuf, so in outer protobuf it's just opaque bytes.
     00010 010 # Field 2 type length-delimited
     1 0101011  0 0000010 # varint length header (decodes to 0000010 0101011 which is 299)

# Rest of message to parse
[ab 2 8 0 12 a6 2 30 82 1 22 30 d 6 9 2a 86 48 86 f7 d 1 1 1 5 0 3 82 1 f 0 30 82 1 a 2 82 1 1 0 d6 2f bf 96 aa 27 ba c0 ef d8 9a 5c 24 79 a6 8a df b6 20 b1 a2 b4 60 60 a2 c4 16 be c7 5c 10 8e 32 e7 9a 5 66 9f 90 29 9d a5 1f 1c c9 23 f8 2 47 fa 8a da 68 1b 9c b7 ab 65 ca a7 b1 b0 23 d0 17 48 a6 19 61 43 69 55 77 20 e3 7a b1 45 ef b1 b1 ab d6 eb 98 92 a1 a0 9a a5 ae 94 48 4b ae bb 8e fc ce 60 59 d2 52 6c d0 9 96 5 7e b3 e1 b8 cf 94 1c 3e d7 ff bd 90 a8 96 4b 3d b3 56 10 18 5f 48 b a6 35 16 c4 a5 3c c4 c 36 11 a3 87 b2 45 a4 c2 b9 cd 2b 15 c6 b a3 36 d9 8d f6 5 43 8b 72 1d 9a 7c a6 80 ce 5 d9 d4 1d 11 83 8d 34 54 33 fb b3 42 45 ab 40 67 c 24 47 fe a3 87 7 ec 41 dc eb 2f c4 fc 94 fd 8a bc bb 6e 31 58 89 6 5 c1 cb 46 12 41 6f 1f 28 ed 63 e0 e7 76 fc ad 38 96 49 9a 21 12 28 f0 41 d0 ce 77 44 ae a1 3a 2f b2 7d 4c 87 cb 96 1f 20 18 e1 5a 5d 5a 59 2 3 1
0 1 1a 11 50 2d 32 35 36 2c 50 2d 33 38 34 2c 50 2d 35 32 31 22 8 42 6c 6f 77 66 69 73 68 2a d 53 48 41 32 35 36 2c 53 48 41 35 31 32]
