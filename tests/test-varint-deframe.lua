local deframe = require 'varint-deframe'
local Utils = require './utils'
local iterList = Utils.iterList
local listIter = Utils.listIter
local listEqual = Utils.listEqual

local function test(inputs, outputs)
  local results = iterList(deframe(listIter(inputs)))
  local passed = listEqual(results, outputs)
  p('INPUT ', inputs)
  p('EXPECTED', outputs)
  p('ACTUAL', results)
  p('passed', passed)
  if not passed then
    error 'Test case failed!'
  end
end

test({'\x0a1234567890'}, {'1234567890'})
test({'\x0a123456789012'}, {'1234567890'})
test({'\x0a', '1234567890'}, {'1234567890'})
test({'\x0a1234', '567890'}, {'1234567890'})
test({'\x0a1', '234', '56789', '0'}, {'1234567890'})
test({'\x03123\x03123'}, {'123', '123'})
test({'\x03123\x03', '123'}, {'123', '123'})
test({'\x0312', '3\x03123'}, {'123', '123'})
test({'\x80\x01' .. string.rep('X', 128)}, {string.rep('X', 128)})
test({'\xac\x02' .. string.rep('X', 300)}, {string.rep('X', 300)})
