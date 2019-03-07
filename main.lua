-- luacheck: globals p

local connect = require "socket"
local wrap = require "socket-channel"
local varint = require "varint"

local function readFrame(socket)
    local length, err = varint.read(socket.next)
    if not length then
        return nil, err
    end
    return socket.read(length)
end

local function writeFrame(socket, message)
    return socket.write(varint.write(#message) .. message)
end

-- local mplex = require "mplex-codec"

local function main()
    print "Connecting..."
    local socket = wrap(assert(connect {host = "127.0.0.1", port = 4001}))
    print "Connected!"
    p(socket.socket:getpeername())

    -- Negotiate protocol
    -- For now, require plaintext
    -- Start test server with `ipfs daemon --disable-transport-encryption`
    local first = readFrame(socket)
    p(first)
    assert(first == "/multistream/1.0.0\n", "Expected multistream/1.0.0 server")
    writeFrame(socket, "/multistream/1.0.0\n")
    writeFrame(socket, "/plaintext/1.0.0\n")
    assert(readFrame(socket) == "/plaintext/1.0.0\n", "Expected negotiation for plaintext/1.0.0")
    -- Expect another multistream line?
    -- TODO: understand why this is sent.
    assert(readFrame(socket) == "/multistream/1.0.0\n")


    print("READY")
end

coroutine.wrap(main)()

require("uv").run()
