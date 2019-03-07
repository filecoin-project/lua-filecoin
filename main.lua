-- luacheck: globals p

local connect = require("coro-net").connect
local varint = require "varint-codec"


print "Hello Filecoin"
coroutine.wrap(
    function()
        print "Connecting..."
        local read, write, socket =
            assert(
            connect {
                host = "127.0.0.1",
                port = 4001,
                encode = varint.encode,
                decode = varint.decode
            }
        )
        print "Connected!"
        p(socket:getpeername())

        -- Negotiate protocol
        -- For now, require plaintext
        -- Start test server with `ipfs daemon --disable-transport-encryption`
        assert(read() == "/multistream/1.0.0", "Expected multistream/1.0.0 server")
        write "/multistream/1.0.0"
        write "/plaintext/1.0.0"
        assert(read() == "/plaintext/1.0.0", "Expected negoiation for plaintext/1.0.0")
        -- Expect another multistream line?
        -- TODO: understand why this is sent.
        assert(read() == "/multistream/1.0.0", "Expected multistream/1.0.0 server")

        print("READY")
    end
)()

require("uv").run()
