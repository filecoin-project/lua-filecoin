local uv = require 'uv'
local checker = uv.new_check()
local idler = uv.new_idle()
local immediateQueue = {}

local Utils = {}

local function onCheck()
  local queue = immediateQueue
  immediateQueue = {}
  for i = 1, #queue do
    queue[i]()
  end
  -- If the queue is still empty, we processed them all
  -- Turn the check hooks back off.
  if #immediateQueue == 0 then
    uv.check_stop(checker)
    uv.idle_stop(idler)
  end
end

function Utils.setImmediate(callback)
  -- If the queue was empty, the check hooks were disabled.
  -- Turn them back on.
  if #immediateQueue == 0 then
    uv.check_start(checker, onCheck)
    uv.idle_start(idler, onCheck)
  end

  immediateQueue[#immediateQueue + 1] = callback
end

local setImmediate = Utils.setImmediate

function Utils.mockStream()
  local queue = {}
  local size = 0
  local onRead
  local stream = {}

  local function flush()
    if onRead and size > 0 then
      local value = table.remove(queue, 1)
      size = size - 1
      pcall(onRead, nil, value)
      setImmediate(flush)
    end
  end

  function stream.push(value)
    size = size + 1
    queue[size] = value
    setImmediate(flush)
  end

  function stream:read_start(cb)
    -- p('read_start')
    onRead = cb
    setImmediate(flush)
  end

  function stream:read_stop()
    -- p('read_stop')
    onRead = nil
  end

  return stream
end

-- Convert a list into an interator
function Utils.listIter(t)
  local i = 0
  return function()
    i = i + 1
    return t[i]
  end
end

-- Convert an iterator into a list
function Utils.iterList(it)
  local results = {}
  local i = 1
  for value in it do
    results[i] = value
    i = i + 1
  end
  return results
end

-- Return true if two lists are identical, false if not.
function Utils.listEqual(a, b)
  if #a ~= #b then
    return false
  end
  for i = 1, #a do
    if a[i] ~= b[i] then
      return false
    end
  end
  return true
end

return Utils
