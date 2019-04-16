local makeCallback = require('make-callback')
local Connection = require 'connection'

-- This is a simple wrapper around raw libuv streams that lets
-- us have pull-style streams with a nice coroutine based interface.
-- Read calls will block till there is data.
-- Write calls will block will the buffer is no longer full (applying backpressure).
-- The read calls will automatically pause and resume the read stream to apply
-- backpressure to the remote writer as well.
return function(socket, onError)
  local paused = true
  local stream = Connection.newPush()

  function stream.onStart()
    if not paused then
      return
    end
    paused = false
    local function onRead(error, value)
      p('in', value)
      if error and onError then
        onError(error)
      end
      return stream.onChunk(value)
    end
    socket:read_start(onRead)
  end

  function stream.onStop()
    if paused then
      return
    end
    paused = true
    socket:read_stop()
  end

  function stream.writeChunk(value)
    p('out', value)
    socket:write(value, makeCallback())
    coroutine.yield()
  end

  stream.socket = socket
  return stream
end