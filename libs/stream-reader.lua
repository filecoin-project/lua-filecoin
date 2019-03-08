
-- makeReader(stream) -> read
--   stream:read_start(onRead)
--     onRead(err, val)
--   stream:read_stop()
--   read() -> chunk or nil
return function(stream, onError)
  local queue = {}
  local reads = 1
  local writes = 1
  local paused = true

  local function onRead(err, val)
    -- Report the error if there is one.
    if err and onError then
      onError(err)
    end
    -- If there was a waiting reader, give it the value.
    if reads > writes then
      local thread
      thread, queue[writes] = queue[writes], nil
      writes = writes + 1
      return assert(coroutine.resume(thread, val))
    end

    -- If we're not paused and nobody is waiting for the data, pause it.
    if not paused and writes > reads then
      paused = true
      stream:read_stop()
    end

    -- Store the value in the queue waiting for a reader.
    queue[writes] = val
    writes = writes + 1
  end

  return function()
    -- If there is a value waiting for us, return it.
    if writes > reads then
      local value
      value, queue[reads] = queue[reads], nil
      reads = reads + 1
      return value
    end

    -- If we need more data and the stream is paused, unpause it.
    if paused then
      paused = false
      stream:read_start(onRead)
    end

    -- Wait for the result.
    queue[reads] = coroutine.running()
    reads = reads + 1
    return coroutine.yield()
  end
end
