local defer = require 'defer'
local makeReader = require 'stream-reader'
local Utils = require './utils'
local mockStream = Utils.mockStream
local deadbeef = Utils.deadbeef

local function pause()
  local thread = coroutine.running()
  defer(
    function()
      assert(coroutine.resume(thread))
    end
  )
  coroutine.yield()
end

local function test(index)
  local stream = mockStream()
  local read = makeReader(stream)
  local random = deadbeef(index * 13)

  coroutine.wrap(
    function()
      for i = 1, 100 do
        if random() % 2 == 1 then
          pause()
        end
        stream.push('item-' .. i)
      end
      if random() % 2 == 1 then
        pause()
      end
      stream.push(nil)
    end
  )()

  coroutine.wrap(
    function()
      local i = 0
      for item in read do
        if random() % 2 == 1 then
          pause()
        end
        i = i + 1
        assert(item == "item-" .. i, "Item out of order on test " .. index)
      end
      assert(i == 100, "expected 100 " .. index)
      print("Passed " .. index)
    end
  )()
end

for i = 1, 1000 do
  test(i)
end
