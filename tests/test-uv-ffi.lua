local loop = require 'uv-ffi'
local wrapStream = require 'wrap-stream'
local httpCodec = require 'http-codec'

local function main()
  local client = loop:newTcp()

  print('Connecting...')
  local res = assert(loop:getaddrinfo('luvit.io', 'http', {socktype = 'stream'})[1])
  p(res)
  local addr = res.addr
  local port = res.port
  client:connect(addr, port)
  print('Connected!')

  local read, write, close = wrapStream(client)
  local encode = httpCodec.encoder()
  local decode = httpCodec.decoder()

  print('Writing')
  write(
    encode {
      method = 'GET',
      path = '/',
      {'Host', 'localhost:8080'},
      {'User-Agent', 'luvit'},
      {'Accept', '*.*'},
      {'Connection', 'close'}
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
      local timer = loop:newTimer()
      timer:sleep(100)
      timer:close()
      index = newIndex
    else
      local chunk = read()
      if not chunk then
        break
      end
      buffer = buffer .. chunk
    end
  end

  write()
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
collectgarbage()
collectgarbage()
loop:run 'DEFAULT'

loop:walk(
  function(handle)
    p('auto-closing handle', handle)
    if not handle:isClosing() then
      handle:close()
    end
  end
)

loop:run 'DEFAULT'

loop:close()
