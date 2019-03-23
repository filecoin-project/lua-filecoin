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

### Step 3 - Send expected messages to verify encryption is working.
