The multistream docs are out of date https://github.com/multiformats/multistream-select

When first connecting, the server sends a varint framed message with `/multistream/1.0.0`
We respond with `/multistream/1.0.0` and then request `/plaintext/1.0.0` and it confirms or rejects.
