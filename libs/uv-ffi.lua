local ffi = require 'ffi'
local cast = ffi.cast
local C = ffi.C
local UV = ffi.load('uv')

if ffi.os == 'Windows' then
  ffi.cdef [[
    typedef struct uv_buf_t {
      ULONG len;
      char* base;
    } uv_buf_t;
  ]]
else
  ffi.cdef [[
    typedef struct uv_buf_t {
      char* base;
      size_t len;
    } uv_buf_t;
  ]]
end

ffi.cdef [[
  uv_buf_t uv_buf_init(char* base, unsigned int len);

  typedef enum {
    UV_EOF = -4095
  } uv_errno_t;

  typedef enum {
    UV_UNKNOWN_HANDLE = 0,
    UV_ASYNC,
    UV_CHECK,
    UV_FS_EVENT,
    UV_FS_POLL,
    UV_HANDLE,
    UV_IDLE,
    UV_NAMED_PIPE,
    UV_POLL,
    UV_PREPARE,
    UV_PROCESS,
    UV_STREAM,
    UV_TCP,
    UV_TIMER,
    UV_TTY,
    UV_UDP,
    UV_SIGNAL,
    UV_FILE,
    UV_HANDLE_TYPE_MAX
  } uv_handle_type;

  typedef enum {
    UV_UNKNOWN_REQ = 0,
    UV_REQ,
    UV_CONNECT,
    UV_WRITE,
    UV_SHUTDOWN,
    UV_UDP_SEND,
    UV_FS,
    UV_WORK,
    UV_GETADDRINFO,
    UV_GETNAMEINFO,
    UV_REQ_TYPE_MAX,
  } uv_req_type;

  size_t uv_loop_size(void);
  size_t uv_req_size(uv_req_type type);
  size_t uv_handle_size(uv_handle_type type);
]]

ffi.cdef(
  string.format(
    [[
    struct uv_loop_s {uint8_t _[%d];};
    struct uv_connect_s {uint8_t _[%d];};
    struct uv_write_s {uint8_t _[%d];};
    struct uv_shutdown_s {uint8_t _[%d];};
    struct uv_tcp_s {uint8_t _[%d];};
    struct uv_timer_s {uint8_t _[%d];};
  ]],
    tonumber(UV.uv_loop_size()),
    tonumber(UV.uv_req_size(UV.UV_CONNECT)),
    tonumber(UV.uv_req_size(UV.UV_WRITE)),
    tonumber(UV.uv_req_size(UV.UV_SHUTDOWN)),
    tonumber(UV.uv_handle_size(UV.UV_TCP)),
    tonumber(UV.uv_handle_size(UV.UV_TIMER))
  )
)

ffi.cdef [[
  typedef struct uv_loop_s uv_loop_t;
  typedef struct uv_req_s uv_req_t;
  typedef struct uv_write_s uv_write_t;
  typedef struct uv_connect_s uv_connect_t;
  typedef struct uv_shutdown_s uv_shutdown_t;
  typedef struct uv_handle_s uv_handle_t;
  typedef struct uv_stream_s uv_stream_t;
  typedef struct uv_tcp_s uv_tcp_t;
  typedef struct uv_timer_s uv_timer_t;

  typedef enum uv_run_mode_e {
    UV_RUN_DEFAULT = 0,
    UV_RUN_ONCE,
    UV_RUN_NOWAIT
  } uv_run_mode;

  struct in_addr {
    unsigned long s_addr;
  };

  struct sockaddr_in {
    short            sin_family;
    unsigned short   sin_port;
    struct in_addr   sin_addr;
    char             sin_zero[8];
  };

  int uv_ip4_addr(const char* ip, int port, struct sockaddr_in* addr);
  int uv_ip6_addr(const char* ip, int port, struct sockaddr_in6* addr);

  const char* uv_err_name(int err);
  const char* uv_strerror(int err);
]]

local function makeCallback(type)
  local thread = coroutine.running()
  local cb
  cb =
    cast(
    type,
    function(...)
      cb:free()
      assert(coroutine.resume(thread, ...))
    end
  )
  return cb
end

local function uvGetError(status)
  return ffi.string(UV.uv_err_name(status)) .. ': ' .. ffi.string(UV.uv_strerror(status))
end

local function uvCheck(status)
  if status < 0 then
    error(uvGetError(status))
  else
    return status
  end
end

-------------------------------------------------------------------------------
-- Req
-------------------------------------------------------------------------------

ffi.cdef [[
  int uv_cancel(uv_req_t* req);
  uv_req_type uv_req_get_type(const uv_req_t* req);
  const char* uv_req_type_name(uv_req_type type);
]]

local Req = {}

function Req:cancel()
  return uvCheck(UV.uv_cancel(cast('uv_req_t*', self)))
end

function Req:getType()
  local id = UV.uv_req_get_type(cast('uv_req_t*', self))
  return ffi.string(UV.uv_req_type_name(id))
end

-------------------------------------------------------------------------------
-- Connect
-------------------------------------------------------------------------------

local Connect = setmetatable({}, {__index = Req})
Connect.type = ffi.typeof 'uv_connect_t'
ffi.metatype(Connect.type, {__index = Connect})
function Connect.new()
  return Connect.type()
end

-------------------------------------------------------------------------------
-- Write
-------------------------------------------------------------------------------

local Write = setmetatable({}, {__index = Req})
Write.type = ffi.typeof 'uv_write_t'
ffi.metatype(Write.type, {__index = Write})
function Write.new()
  return Write.type()
end

-------------------------------------------------------------------------------
-- Shutdown
-------------------------------------------------------------------------------

local Shutdown = setmetatable({}, {__index = Req})
Shutdown.type = ffi.typeof 'uv_shutdown_t'
ffi.metatype(Shutdown.type, {__index = Shutdown})
function Shutdown.new()
  return Shutdown.type()
end

-------------------------------------------------------------------------------
-- Handle
-------------------------------------------------------------------------------

ffi.cdef [[
  typedef void (*uv_walk_cb)(uv_handle_t* handle, void* arg);
  typedef void (*uv_close_cb)(uv_handle_t* handle);
  typedef void (*uv_alloc_cb)(uv_handle_t* handle, size_t suggested_size, uv_buf_t* buf);
  void *malloc(size_t size);
  void free(void *ptr);

  int uv_is_active(const uv_handle_t* handle);
  int uv_is_closing(const uv_handle_t* handle);
  void uv_close(uv_handle_t* handle, uv_close_cb close_cb);
  void uv_ref(uv_handle_t* handle);
  void uv_unref(uv_handle_t* handle);
  int uv_has_ref(const uv_handle_t* handle);
  int uv_send_buffer_size(uv_handle_t* handle, int* value);
  int uv_recv_buffer_size(uv_handle_t* handle, int* value);
  uv_loop_t* uv_handle_get_loop(const uv_handle_t* handle);
  void* uv_handle_get_data(const uv_handle_t* handle);
  void* uv_handle_set_data(uv_handle_t* handle, void* data);
  uv_handle_type uv_handle_get_type(const uv_handle_t* handle);
  const char* uv_handle_type_name(uv_handle_type type);
]]

local function onAlloc(handle, suggestedSize, buf)
  local cached = cast('uv_buf_t*', UV.uv_handle_get_data(handle))
  if cached ~= nil then
    buf.base = cached.base
    buf.len = cached.len
  else
    local base = C.malloc(suggestedSize)
    buf.base = base
    buf.len = suggestedSize
    -- Store the data in handle->data as a uv_buf_t*
    local data = cast('uv_buf_t*', C.malloc(ffi.sizeof 'uv_buf_t'))
    data.base = base
    data.len = suggestedSize
    UV.uv_handle_set_data(handle, data)
  end
end

local allocCb = cast('uv_alloc_cb', onAlloc)

local Handle = {}

function Handle:isActive()
  return UV.uv_is_active(cast('uv_handle_t*', self)) ~= 0
end

function Handle:isClosing()
  return UV.uv_is_closing(cast('uv_handle_t*', self)) ~= 0
end

function Handle:close()
  local handle = cast('uv_handle_t*', self)
  UV.uv_close(handle, makeCallback 'uv_close_cb')
  coroutine.yield()
  local cached = cast('uv_buf_t*', UV.uv_handle_get_data(handle))
  if cached ~= nil then
    C.free(cached.base)
    C.free(cached)
  end
end

function Handle:ref()
  return UV.uv_ref(cast('uv_handle_t*', self))
end

function Handle:unref()
  return UV.uv_unref(cast('uv_handle_t*', self))
end

function Handle:hasRef()
  return UV.uv_has_ref(cast('uv_handle_t*', self)) ~= 0
end

function Handle:setSendBufferSize(value)
  uvCheck(UV.uv_send_buffer_size(cast('uv_handle_t*', self), value))
end

function Handle:getSendBufferSize()
  local out = ffi.new('int[1]')
  uvCheck(UV.uv_send_buffer_size(cast('uv_handle_t*', self), out))
  return out[0]
end

function Handle:setRecvBufferSize(value)
  uvCheck(UV.uv_recv_buffer_size(cast('uv_handle_t*', self), value))
end

function Handle:getRecvBufferSize()
  local out = ffi.new('int[1]')
  uvCheck(UV.uv_recv_buffer_size(cast('uv_handle_t*', self), out))
  return out[0]
end

function Handle:getLoop()
  return UV.uv_handle_get_loop(cast('uv_handle_t*', self))
end

function Handle:getType()
  local id = UV.uv_handle_get_type(cast('uv_handle_t*', self))
  return ffi.string(UV.uv_handle_type_name(id))
end

-------------------------------------------------------------------------------
-- Stream
-------------------------------------------------------------------------------

ffi.cdef [[
  typedef void (*uv_read_cb)(uv_stream_t* stream, int64_t nread, const uv_buf_t* buf);
  typedef void (*uv_write_cb)(uv_write_t* req, int status);
  typedef void (*uv_connect_cb)(uv_connect_t* req, int status);
  typedef void (*uv_shutdown_cb)(uv_shutdown_t* req, int status);
  typedef void (*uv_connection_cb)(uv_stream_t* server, int status);

  int uv_shutdown(uv_shutdown_t* req, uv_stream_t* handle, uv_shutdown_cb cb);
  int uv_listen(uv_stream_t* stream, int backlog, uv_connection_cb cb);
  int uv_accept(uv_stream_t* server, uv_stream_t* client);
  int uv_read_start(uv_stream_t* stream, uv_alloc_cb alloc_cb, uv_read_cb read_cb);
  int uv_read_stop(uv_stream_t*);
  int uv_write(uv_write_t* req, uv_stream_t* handle, const uv_buf_t bufs[], unsigned int nbufs, uv_write_cb cb);
  int uv_write2(uv_write_t* req, uv_stream_t* handle, const uv_buf_t bufs[], unsigned int nbufs, uv_stream_t* send_handle, uv_write_cb cb);
  int uv_try_write(uv_stream_t* handle, const uv_buf_t bufs[], unsigned int nbufs);
  int uv_is_readable(const uv_stream_t* handle);
  int uv_is_writable(const uv_stream_t* handle);
  int uv_stream_set_blocking(uv_stream_t* handle, int blocking);
  size_t uv_stream_get_write_queue_size(const uv_stream_t* stream);
]]

local Stream = setmetatable({}, {__index = Handle})

function Stream:shutdown()
  local req = Shutdown.new()
  uvCheck(UV.uv_shutdown(req, cast('uv_stream_t*', self), makeCallback 'uv_shutdown_cb'))
  local _, status = coroutine.yield()
  uvCheck(status)
end

function Stream:listen(backlog, onConnection)
  local cb = cast('uv_connection_cb', onConnection)
  uvCheck(UV.uv_listen(cast('uv_stream_t*', self), backlog, cb))
  return cb
end

function Stream:accept(client)
  uvCheck(UV.uv_accept(cast('uv_stream_t*', self), cast('uv_stream_t*', client)))
end

function Stream:read()
  local stream = cast('uv_stream_t*', self)
  while true do
    uvCheck(UV.uv_read_start(stream, allocCb, makeCallback 'uv_read_cb'))
    local _, status, buf = coroutine.yield()
    p(status, buf)
    UV.uv_read_stop(stream)
    if status == UV.UV_EOF then
      return
    end
    if status < 0 then
      uvCheck(status)
    end
    if status > 0 then
      return ffi.string(buf.base, status)
    end
  end
end

function Stream:readStart(onRead)
  setmetatable(
    onRead,
    {
      __gc = function()
        p('READ GCed')
      end
    }
  )
  local function onEvent(_, status, buf)
    if status == 0 then
      return
    end
    if status < 0 then
      return onRead(uvGetError(status))
    elseif status == UV.UV_EOF then
      onRead(nil)
    else
      onRead(nil, ffi.string(buf.base, buf.len))
    end
  end
  local cb = cast('uv_read_cb', onEvent)
  uvCheck(UV.uv_read_start(cast('uv_stream_t*', self), allocCb, cb))
end

function Stream:readStop()
  uvCheck(UV.uv_read_stop(cast('uv_stream_t*', self)))
end

function Stream:write(data)
  local req = Write.new()
  local bufs = ffi.new('uv_buf_t[1]')
  bufs[0].base = cast('char*', data)
  bufs[0].len = #data
  local cb = makeCallback 'uv_write_cb'
  uvCheck(UV.uv_write(req, cast('uv_stream_t*', self), bufs, 1, cb))
  local _, status = coroutine.yield()
  uvCheck(status)
end

function Stream:write2(handle)
  local req = Write.new()
  local cb = makeCallback 'uv_write_cb'
  uvCheck(UV.uv_write(req, cast('uv_stream_t*', self), nil, 0, cast('uv_stream_t*', handle), cb))
  local _, status = coroutine.yield()
  uvCheck(status)
end

function Stream:tryWrite(data)
  local bufs = ffi.new('uv_buf_t[1]')
  bufs[0].base = cast('char*', data)
  bufs[0].len = #data
  return uvCheck(UV.uv_try_write(cast('uv_stream_t*', self), bufs, 1))
end

function Stream:isReadable()
  return UV.uv_is_readable(cast('uv_stream_t*', self)) ~= 0
end

function Stream:isWritable()
  return UV.uv_is_writable(cast('uv_stream_t*', self)) ~= 0
end

function Stream:setBlocking(blocking)
  uvCheck(UV.uv_set_blocking(cast('uv_stream_t*', blocking)))
end

function Stream:getWriteQueueSize()
  return UV.uv_stream_get_write_queue_size(cast('uv_stream_t*', self))
end

-------------------------------------------------------------------------------
-- Tcp
-------------------------------------------------------------------------------

ffi.cdef [[
  int uv_tcp_init(uv_loop_t* loop, uv_tcp_t* handle);
  int uv_tcp_bind(uv_tcp_t* handle, const struct sockaddr* addr, unsigned int flags);
  int uv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle, const struct sockaddr_in* addr, uv_connect_cb cb);
]]

local Tcp = setmetatable({}, {__index = Stream})
Tcp.type = ffi.typeof 'uv_tcp_t'

function Tcp.new(loop)
  local tcp = Tcp.type()
  tcp:init(loop)
  return tcp
end

function Tcp:init(loop)
  return uvCheck(UV.uv_tcp_init(loop, self))
end

function Tcp:getsockname()
  return UV.uv_tcp_getsockname(self)
end

function Tcp:getpeername()
end

function Tcp:connect(host, port)
  local req = Connect.new()
  local addr = ffi.new 'struct sockaddr_in'
  UV.uv_ip4_addr(host, port, addr)
  uvCheck(UV.uv_tcp_connect(req, self, addr, makeCallback 'uv_connect_cb'))
  local _, status = coroutine.yield()
  return uvCheck(status)
end

ffi.metatype(Tcp.type, {__index = Tcp})

-------------------------------------------------------------------------------
-- Timer
-------------------------------------------------------------------------------

ffi.cdef [[
  typedef void (*uv_timer_cb)(uv_timer_t* handle);

  int uv_timer_init(uv_loop_t* loop, uv_timer_t* handle);
  int uv_timer_start(uv_timer_t* handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat);
  int uv_timer_stop(uv_timer_t* handle);
  int uv_timer_again(uv_timer_t* handle);
  void uv_timer_set_repeat(uv_timer_t* handle, uint64_t repeat);
  uint64_t uv_timer_get_repeat(const uv_timer_t* handle);
]]

local Timer = setmetatable({}, {__index = Handle})
Timer.Type = ffi.typeof 'uv_timer_t'

function Timer.new(loop)
  local timer = Timer.Type()
  timer:init(loop)
  return timer
end

function Timer:init(loop)
  uvCheck(UV.uv_timer_init(loop, self))
end

function Timer:sleep(timeout)
  uvCheck(UV.uv_timer_start(self, makeCallback 'uv_timer_cb', timeout, 0))
  coroutine.yield()
  uvCheck(UV.uv_timer_stop(self))
end

function Timer:start(callback, timeout, rep)
  local cb = cast('uv_timer_cb', timeout)
  uvCheck(UV.uv_timer_start(self, callback, cb, rep))
  return cb
end

function Timer:stop()
  uvCheck(UV.uv_timer_stop(self))
end

function Timer:again()
  uvCheck(UV.uv_timer_again(self))
end

function Timer:setRepeat(rep)
  uvCheck(UV.uv_timer_set_repeat(self, rep))
end

function Timer:getRepeat()
  return UV.uv_timer_get_repeat(self)
end

local function onGc(handle)
  if not handle:isClosing() then
    p('auto closing...', handle._)
    UV.uv_close(cast('uv_handle_t*', handle), nil)
    return true
  end
  return false
end

ffi.metatype(Timer.Type, {__index = Timer, __gc = onGc})

-------------------------------------------------------------------------------
-- Loop
-------------------------------------------------------------------------------

ffi.cdef [[
  int uv_loop_init(uv_loop_t* loop);
  int uv_loop_close(uv_loop_t* loop);
  int uv_loop_alive(const uv_loop_t* loop);
  void uv_stop(uv_loop_t* loop);
  uint64_t uv_now(const uv_loop_t* loop);
  void uv_update_time(uv_loop_t* loop);
  void uv_walk(uv_loop_t* loop, uv_walk_cb walk_cb, void* arg);
  int uv_run(uv_loop_t* loop, uv_run_mode mode);
]]

local Loop = {}
local LoopType = ffi.typeof 'uv_loop_t'

function Loop.new()
  local loop = LoopType()
  loop:init()
  return loop
end

function Loop:newTimer()
  return Timer.new(self)
end

function Loop:newTcp()
  return Tcp.new(self)
end

function Loop:init()
  return uvCheck(UV.uv_loop_init(self))
end

function Loop:close()
  return uvCheck(UV.uv_loop_close(self))
end

function Loop:alive()
  return UV.uv_loop_alive(self) ~= 0
end

function Loop:stop()
  return UV.uv_loop_stop(self)
end

function Loop:now()
  return UV.uv_loop_now(self)
end

function Loop:updateTime()
  return UV.uv_update_time(self)
end

function Loop:walk(callback)
  local function onHandle(handle)
    callback(cast('uv_' .. Handle.getType(handle) .. '_t*', handle))
  end
  local cb = cast('uv_walk_cb', onHandle)
  UV.uv_walk(self, cb, nil)
  cb:free()
end

function Loop:run(mode)
  mode = assert(UV['UV_RUN_' .. mode], 'Unknown run mode')
  return uvCheck(UV.uv_run(self, mode))
end

ffi.metatype(LoopType, {__index = Loop})

-------------------------------------------------------------------------------

Loop.Handle = Handle

return Loop
