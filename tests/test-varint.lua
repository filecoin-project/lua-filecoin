local Varint = require 'varint'
local deframe = Varint.deframe
local frame = Varint.frame
local decode = Varint.decode
local encode = Varint.encode
local Utils = require './utils'
local listIter = Utils.listIter
local iterList = Utils.iterList
local listEqual = Utils.listEqual

local function testDeframe(inputs, outputs)
  local results = iterList(deframe(listIter(inputs)))
  local passed = listEqual(results, outputs)
  p('INPUT ', inputs)
  p('EXPECTED', outputs)
  p('ACTUAL', results)
  p('passed', passed)
  if not passed then
    error 'testDeframe case failed!'
  end
end

-- input is result table, output is write function
local function resultWriter(result)
  local size = 0
  return function(value)
    size = size + 1
    result[size] = value
  end
end

local function listWriter(list, write)
  for i = 1, #list do
    write(list[i])
  end
end

local function testFrame(inputs, outputs)
  local results = {}
  listWriter(inputs, frame(resultWriter(results)))
  local passed = listEqual(results, outputs)
  p('INPUT ', inputs)
  p('EXPECTED', outputs)
  p('ACTUAL', results)
  p('passed', passed)
  if not passed then
    error 'testFrame case failed!'
  end
end

assert(decode('\x00', 1) == 0)
assert(decode('\x33', 1) == 0x33)
assert(decode('\x7f', 1) == 127)
assert(decode('\x80\x01', 1) == 128)
assert(decode('\x81\x01', 1) == 129)
assert(decode('\xac\x02', 1) == 300)

assert(encode(0) == '\x00')
assert(encode(0x33) == '\x33')
assert(encode(127) == '\x7f')
assert(encode(128) == '\x80\x01')
assert(encode(129) == '\x81\x01')
assert(encode(300) == '\xac\x02')

testFrame({'1234567890'}, {'\x0a', '1234567890'})
testFrame({'1234567890', '123'}, {'\x0a', '1234567890', '\x03', '123'})
testFrame({string.rep('X', 128)}, {'\x80\x01' , string.rep('X', 128)})
testFrame({string.rep('X', 300)}, {'\xac\x02' , string.rep('X', 300)})

testDeframe({'\x0a1234567890'}, {'1234567890'})
testDeframe({'\x0a123456789012'}, {'1234567890'})
testDeframe({'\x0a', '1234567890'}, {'1234567890'})
testDeframe({'\x0a1234', '567890'}, {'1234567890'})
testDeframe({'\x0a1', '234', '56789', '0'}, {'1234567890'})
testDeframe({'\x03123\x03123'}, {'123', '123'})
testDeframe({'\x03123\x03', '123'}, {'123', '123'})
testDeframe({'\x0312', '3\x03123'}, {'123', '123'})
testDeframe({'\x80\x01' .. string.rep('X', 128)}, {string.rep('X', 128)})
testDeframe({'\xac\x02' .. string.rep('X', 300)}, {string.rep('X', 300)})
