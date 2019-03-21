local Loop = require 'uv-ffi'
local httpCodec = require 'http-codec'

local loop = Loop.new()

local function main()
  local client = loop:newTcp()
  local encode = httpCodec.encoder()
  local decode = httpCodec.decoder()

  print('Connecting...')
  client:connect('127.0.0.1', 8080)
  print('Connected!')
  print('Writing')
  client:write(
    encode {
      method = 'GET',
      path = '/README.md',
      {'Host', 'localhost:8080'},
      {'User-Agent', 'luvit'},
      {'Accept', '*.*'}
      -- {'Connection', 'close'}
    }
  )
  print('reading')
  local buffer = ''
  local index = 0
  while true do
    local out, newIndex = decode(buffer, index)
    if out then
      if out == '' then
        break
      end
      p(out)
      loop:newTimer():sleep(10)
      print('waited')
      index = newIndex
    else
      local chunk = client:read()
      if not chunk then
        break
      end
      buffer = buffer .. chunk
    end
  end

  client:shutdown()
  client:close()
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
-- collectgarbage()
-- collectgarbage()
loop:walk(
  function(handle)
    p('walk', handle)
  end
)
collectgarbage()
collectgarbage()

loop:run 'DEFAULT'
collectgarbage()
collectgarbage()
loop:close()
