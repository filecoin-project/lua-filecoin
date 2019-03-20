local newLoop = require 'uv-ffi'

local loop = newLoop()

local function main()
  local client = loop:newTcp()
  print('Connecting...')
  client:connect('127.0.0.1', 8080)
  print('Connected!')
  p(client)
end

coroutine.wrap(
  function()
    local success, error = xpcall(main, debug.traceback)
    if not success then
      print(error)
      os.exit(-1)
    end
  end
)()

loop:run 'DEFAULT'
loop:close()
