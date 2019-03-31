return function(stream)
  local writing = true
  local reading = true
  local closed = false
  local paused = true
  local queue = {}
  local reads = 0
  local writes = 0
  local cb

  local function close()
    assert(not closed)
    closed = true
    reading = false
    writing = false
    stream:close()
    if cb then
      cb:free()
      cb = nil
    end
  end

  local function checkClose()
    assert(not closed)
    if reading or writing then
      return
    end
    return close()
  end

  local function onRead(err, data)
    assert(not err, err)
    if not data then
      reading = false
      checkClose()
    end

    if reads > writes then
      local thread
      thread, queue[writes] = queue[writes], nil
      writes = writes + 1
      return coroutine.resume(thread, data)
    end

    if writes > reads and not paused then
      paused = true
      stream:readStop()
    end

    queue[writes] = data
    writes = writes + 1
  end

  local function read()
    assert(reading)
    local data
    if writes > reads then
      data, queue[reads] = queue[reads], nil
      reads = reads + 1
    else
      if paused then
        paused = false
        cb = stream:readStart(cb or onRead)
      end

      queue[reads] = coroutine.running()
      reads = reads + 1

      data = coroutine.yield()
    end
    return data
  end

  local function write(message)
    assert(writing)
    if message then
      stream:write(message)
    else
      writing = false
      stream:shutdown()
      checkClose()
    end
  end

  return read, write, close, stream
end
