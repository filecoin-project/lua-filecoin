local bit = require 'bit'
local lshift = bit.lshift
local rshift = bit.rshift
local bxor = bit.bxor
local defer = require 'defer'

local Utils = {}

-- A simple and fast deterministic random sequence generator.
function Utils.deadbeef(seed)
  local beef = 0xdeadbeef

  return function()
    seed = bxor(lshift(seed, 7), rshift(seed, 25) + beef)
    beef = bxor(lshift(beef, 7), rshift(beef, 25) + 0xdeadbeef)
    return seed
  end
end

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
      defer(flush)
    end
  end

  function stream.push(value)
    size = size + 1
    queue[size] = value
    defer(flush)
  end

  function stream:read_start(cb)
    -- p('read_start')
    onRead = cb
    defer(flush)
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
