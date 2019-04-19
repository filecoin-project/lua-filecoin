local connect = require 'uv-socket'
local wrapStream = require 'stream-wrap'
local Mplex = require 'mplex'
local Multiselect = require 'multiselect'
local Secio = require 'secio'

local Switch = {}

function Switch.dial(host, port)
  -- Derive read/write functions that work with framed messages
  local stream = wrapStream(assert(connect {host = host, port = port}))

  -- Negotiate protocol
  -- Start test server with `ipfs daemon`
  Multiselect.negotiate(stream, '/secio/1.0.0')
  stream = Secio.wrap(stream)

  -- Upgrade to mplex protocol and return handle to mp object.
  return Mplex.start(stream)
end

return Switch
