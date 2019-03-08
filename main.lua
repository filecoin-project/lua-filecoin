-- luacheck: globals p

local connect = require "socket"
local makeReader = require "stream-reader"
local makeWriter = require "stream-writer"
local Varint = require 'varint'
local deframe = Varint.deframe
local frame = Varint.frame

local function main()
    print "Connecting..."
    local socket = assert(connect {host = "127.0.0.1", port = 4001})
    print "Connected!"
    p(socket:getpeername())

    local readFrame = deframe(makeReader(socket))
    local writeFrame = frame(makeWriter(socket))

    -- Negotiate protocol
    -- For now, require plaintext
    -- Start test server with `ipfs daemon --disable-transport-encryption`
    assert(readFrame() == "/multistream/1.0.0\n", "Expected multistream/1.0.0 server")
    writeFrame("/multistream/1.0.0\n")
    writeFrame("/plaintext/1.0.0\n")
    assert(readFrame() == "/plaintext/1.0.0\n", "Expected negotiation for plaintext/1.0.0")
    -- Expect another multistream line?
    -- TODO: understand why this is sent.
    assert(readFrame() == "/multistream/1.0.0\n")

    -- mplex.write(socket, "NewStream", 42, "Hello")

    print("READY")
end

coroutine.wrap(main)()

require("uv").run()
