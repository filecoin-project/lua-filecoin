local Varint = require 'varint'
local Multiselect = require 'multiselect'
local Connection = require 'connection'

local NewStream = 0
local MessageReceiver = 1
local MessageInitiator = 2
local CloseReceiver = 3
local CloseInitiator = 4
local ResetReceiver = 5
local ResetInitiator = 6

local Mplex = {}

function Mplex.start(masterStream)
  Multiselect.negotiate(masterStream, '/mplex/6.7.0')

  local nextId = 0
  local dead = false

  local mp = {socket = masterStream.socket}

  local streams = {}

  local function getStream(id)
    local stream = streams[id]
    if not stream then
      stream = Connection.newPush()
      streams[id] = stream
    end
    return stream
  end

  local function readLoop()
    while true do
      local head = Varint.read(masterStream)
      if not head then
        break
      end
      local id = head >> 3
      local flag = head & 7
      local frame = Varint.readFrame(masterStream)
      -- p(id, flag, frame)
      if flag == MessageReceiver then
        getStream(id).onChunk(frame)
      end
    end
  end
  coroutine.wrap(readLoop)()

  function mp.newStream(name)
    local id = nextId
    if not name then
      name = '' .. id
    end
    nextId = nextId + 1

    local stream = getStream(id)

    local function sendFrame(flag, body)
      local head = flag | id << 8
      masterStream.writeChunk(Varint.encode(head) .. Varint.encode(#body) .. body)
    end

    sendFrame(NewStream, name)

    function stream.writeChunk(message)
      assert(not dead, 'dead stream')
      if message then
        sendFrame(MessageInitiator, message)
      else
        dead = true
        sendFrame(CloseInitiator, '')
      end
    end

    function stream.start()
      -- TODO: use for backpressure
    end

    function stream.stop()
      -- TODO: apply backpressure somehow?
    end

    return stream
  end

  return mp
end

return Mplex
