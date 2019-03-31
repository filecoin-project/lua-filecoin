local uv = require 'uv'
local checker = uv.new_check()
local idler = uv.new_idle()
local deferQueue = {}
local deferCount = 0

local function onCheck()
  local queue = deferQueue
  local count = deferCount
  deferQueue = {}
  deferCount = 0
  for i = 1, count do
    queue[i]()
  end
  -- If the queue is still empty, we processed them all
  -- Turn the check hooks back off.
  if deferCount == 0 then
    checker:stop()
    idler:stop()
  end
end

return function(callback)
  -- If the queue was empty, the check hooks were disabled.
  -- Turn them back on.
  if deferCount == 0 then
    checker:start(onCheck)
    idler:start(onCheck)
  end

  deferCount = deferCount + 1
  deferQueue[deferCount] = callback
end
