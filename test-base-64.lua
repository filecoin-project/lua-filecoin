local base64 = require 'base-64'(
    'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='
)

assert(base64.encode("") == "")
assert(base64.encode("f") == "Zg==")
assert(base64.encode("fo") == "Zm8=")
assert(base64.encode("foo") == "Zm9v")
assert(base64.encode("foob") == "Zm9vYg==")
assert(base64.encode("fooba") == "Zm9vYmE=")
assert(base64.encode("foobar") == "Zm9vYmFy")

assert(base64.decode("") == "")
assert(base64.decode("Zg==") == "f")
assert(base64.decode("Zm8=") == "fo")
assert(base64.decode("Zm9v") == "foo")
assert(base64.decode("Zm9vYg==") == "foob")
assert(base64.decode("Zm9vYmE=") == "fooba")
assert(base64.decode("Zm9vYmFy") == "foobar")
