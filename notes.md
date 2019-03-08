The multistream docs are out of date https://github.com/multiformats/multistream-select

When first connecting, the server sends a varint framed message with `/multistream/1.0.0\n`

We respond with `/multistream/1.0.0\n` and then request `/plaintext/1.0.0\n` and it confirms or rejects.

Then for some reason it sends `/multistream/1.0.0\n` again?

Now how do we create a mplex stream?  Does `/plaintext/1.0.0` assume mplex without encryption or do we need to do something else?  Also is the mplex with it's own length header tunneled inside framed messages or replace the framed multistream messages?
