local connect = require 'socket'
local wrapStream = require 'stream-wrap'
local Mplex = require 'mplex'
local Multiselect = require 'multiselect'

local Switch = {}

function Switch.dial(host, port)
  -- Derive read/write functions that work with framed messages
  local stream = wrapStream(assert(connect {host = host, port = port}))

  -- Negotiate protocol
  -- For now, require plaintext
  -- Start test server with `ipfs daemon --disable-transport-encryption`
  Multiselect.negotiate(stream, '/plaintext/1.0.0')

  -- Upgrade to mplex protocol and return handle to mp object.
  return Mplex.start(stream)
end

return Switch
