The multistream docs are out of date https://github.com/multiformats/multistream-select

When first connecting, the server sends a varint framed message with `/multistream/1.0.0\n`

We respond with `/multistream/1.0.0\n` and then request `/plaintext/1.0.0\n` and it confirms or rejects.

Then for some reason it sends `/multistream/1.0.0\n` again?

Now how do we create a mplex stream?  Does `/plaintext/1.0.0` assume mplex without encryption or do we need to do something else?  Also is the mplex with it's own length header tunneled inside framed messages or replace the framed multistream messages?

----------------------------------------

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

Notice that there was nothing to do between selecting plaintext and selecting mplex.  Things are a little more complicated with encryption (aka secio).

It starts the same, but selecting `secio/1.0.0` instead of `plaintext/1.0.0`

- negotiate secio
  - Send: `/multistream/1.0.0\n`
  - Expect: `/multistream/1.0.0\n`
  - Send: `/secio/1.0.0\n`
  - Expect: `/secio/1.0.0\n`

But then we need to perform the secio handshake on this transport.  It's similar to TLS except there are no root authorities and certificates.

In secio, there are three different configuration parameters that both parties need to negotiate.  They are:

- ECDH algorithms for key exchange, `P-256`, `P-384`, and `P-521` are common.  I want to see if I can add `Curve25519` as well.
- Cipher to use for actual encryption.  Common options are `AES-256`, `AES-128` and `Blowfish`.  I want to add something `Gimli` based.
- hash used for MAC, common hash algorithms are `SHA256` and `SHA512`.  I want to also use `Gimli` for this.
- Each peer needs to also us a public key for signing part of the handshake and optionally authenticating itself.  This key tends to be `RSA-2048`. I want to use `ED25519` for faster ephermeral key generation.
