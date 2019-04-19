local byte = string.byte
local char = string.char

local Connection = {}

local function wrapRead(readNext)
  -- Extra data from the last frame.
  local chunk = nil
  local index = 0

  -- Get next byte as a number
  -- Returns nil on EOS
  local function readByte()
    while true do
      if not chunk then
        chunk = readNext()
        index = 1
      end
      if not chunk then
        return
      end
      if index <= #chunk then
        local b = byte(chunk, index)
        index = index + 1
        return b
      else
        chunk = nil
      end
    end
  end

  local function readChunk(length)
    local buffer = {}
    for i = 1, length do
      local b = readByte()
      if not b then
        break
      end
      buffer[i] = char(b)
    end
    return table.concat(buffer)
  end

  return readByte, readChunk
end

Connection.wrapRead = wrapRead

function Connection.newPush()
  local queue = {}
  local reads = 1
  local writes = 1

  local stream = {}

  function stream.onChunk(chunk)
    -- If there was a waiting reader, give it the value.
    if reads > writes then
      local thread
      thread, queue[writes] = queue[writes], nil
      writes = writes + 1
      return assert(coroutine.resume(thread, chunk))
    end

    -- If nobody is waiting for the data, pause it.
    if writes > reads and stream.onStop then
      stream.onStop()
    end

    -- Store the value in the queue waiting for a reader.
    queue[writes] = chunk
    writes = writes + 1
  end

  local function readNext()
    -- If there is a value waiting for us, return it.
    if writes > reads then
      local value
      value, queue[reads] = queue[reads], nil
      reads = reads + 1
      return value
    end

    -- If we need more data and the stream is paused, unpause it.
    if stream.onStart then
      stream.onStart()
    end

    -- Wait for the result.
    queue[reads] = coroutine.running()
    reads = reads + 1
    return coroutine.yield()
  end

  local readByte, readChunk = wrapRead(readNext)

  stream.readByte = readByte
  stream.readChunk = readChunk

  return stream
end

return Connection
