local deframe = require 'varint-deframe'

local function test(inputs, outputs)
  local i = 0
  local function rawRead()
    i = i + 1
    return inputs[i]
  end
  local read = deframe(rawRead)
  local results = {}
  while true do
    local out = read()
    if not out then
      break
    end
    results[#results + 1] = out
  end
  local pass = true
  if #outputs ~= #results then
    pass = false
  else
    for index = 1, #outputs do
      if outputs[index] ~= results[index] then
        pass = false
        break
      end
    end
  end
  if not pass then
    p('INPUT ', inputs)
    p('EXPECTED', outputs)
    p('ACTUAL', results)
    error 'Test case failed!'
  end
end

test({'\x0a1234567890'}, {'1234567890'})
test({'\x0a', '1234567890'}, {'1234567890'})
test({'\x0a1234', '567890'}, {'1234567890'})
test({'\x0a1', '234', '56789', '0'}, {'1234567890'})
test({'\x03123\x03123'}, {'123', '123'})
test({'\x03123\x03', '123'}, {'123', '123'})
test({'\x0312', '3\x03123'}, {'123', '123'})
test({'\xac\x02' .. string.rep('X', 300)}, {string.rep('X', 300)})
test({'\x80\x01' .. string.rep('X', 128)}, {string.rep('X', 128)})
