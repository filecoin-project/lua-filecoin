local connect = require 'socket'
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
  print('secio start')
  Multiselect.negotiate(stream, '/secio/1.0.0')
  print('secio middle')

  stream = Secio.wrap(stream)
  print('secio end')

  -- Upgrade to mplex protocol and return handle to mp object.
  return Mplex.start(stream)
end

return Switch
