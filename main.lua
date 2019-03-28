local uv = require 'uv'
local p = require('pretty-print').prettyPrint
_G.p = p

local Switch = require 'switch'
local Multiselect = require 'multiselect'

local function main()
  local mp = Switch.dial('localhost', 4001)
  print 'Connected!'
  p(mp.socket:getpeername())

  local stream = mp.newStream()
  Multiselect.negotiate(stream, '/ipfs/ping/1.0.0')
  print 'Negotiated mplex ping..'

  local ping = string.rep('*', 32)
  local before = uv.hrtime()
  stream.writeChunk(ping)
  assert(stream.readChunk(32) == ping)
  local after = uv.hrtime()
  print('Ping verified!', after - before .. ' μs')

  print('Closing socket...')
  mp.socket:close()
end

coroutine.wrap(main)()
local timer = uv.new_timer()
timer:start(
  1000,
  1000,
  function()
    print('.')
  end
)
uv.run()
