-- luacheck: globals 
local uv = require 'uv'

local Switch = require 'switch'
local Multiselect = require 'multiselect'

local ffi = require 'ffi'
local newBuffer = ffi.typeof('uint8_t[?]')

local function main()
  local mp = Switch.dial('127.0.0.1', 4001)
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
  print("Ping verified!", after - before .. ' μs')

  print('Closing socket...')
  mp.socket:close()
end

coroutine.wrap(main)()

uv.run()
