local ffi = require 'ffi'
local cast = ffi.cast
local UV = ffi.load('uv')

ffi.cdef [[
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

  const char* uv_err_name(int err);
  const char* uv_strerror(int err);

  size_t uv_loop_size(void);
  size_t uv_req_size(uv_req_type type);
  size_t uv_handle_size(uv_handle_type type);

]]

ffi.cdef(string.format(
  [[
    struct uv_loop_s {uint8_t _[%d];};
    struct uv_connect_s {uint8_t _[%d];};
    struct uv_tcp_s {uint8_t _[%d];};
    struct uv_timer_s {uint8_t _[%d];};
  ]],
  tonumber(UV.uv_loop_size()),
  tonumber(UV.uv_req_size(UV.UV_CONNECT)),
  tonumber(UV.uv_handle_size(UV.UV_TCP)),
  tonumber(UV.uv_handle_size(UV.UV_TIMER))
))

ffi.cdef [[
  typedef struct uv_loop_s uv_loop_t;
  typedef struct uv_req_s uv_req_t;
  typedef struct uv_connect_s uv_connect_t;
  typedef struct uv_handle_s uv_handle_t;
  typedef struct uv_stream_s uv_stream_t;
  typedef struct uv_tcp_s uv_tcp_t;
  typedef struct uv_timer_s uv_timer_t;

  typedef void (*uv_walk_cb)(uv_handle_t* handle, void* arg);
  typedef void (*uv_close_cb)(uv_handle_t* handle);
  typedef void (*uv_connect_cb)(uv_connect_t* req, int status);
  typedef void (*uv_timer_cb)(uv_timer_t* handle);

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
]]

-------------------------------------------------------------------------------
-- Handle
-------------------------------------------------------------------------------

ffi.cdef [[
  int uv_is_active(const uv_handle_t* handle);
  int uv_is_closing(const uv_handle_t* handle);
  void uv_close(uv_handle_t* handle, uv_close_cb close_cb);
  void uv_ref(uv_handle_t* handle);
  void uv_unref(uv_handle_t* handle);
  int uv_has_ref(const uv_handle_t* handle);
  uv_handle_type uv_handle_get_type(const uv_handle_t* handle);
  const char* uv_handle_type_name(uv_handle_type type);
]]

local Handle = {}

function Handle:isActive()
  return UV.uv_is_active(cast('uv_handle_t*', self))
end

function Handle:isClosing()
  return UV.uv_is_closing(cast('uv_handle_t*', self))
end

function Handle:close(callback)
  return UV.uv_close(cast('uv_handle_t*', self), callback)
end

function Handle:ref()
  return UV.uv_ref(cast('uv_handle_t*', self))
end

function Handle:unref()
  return UV.uv_unref(cast('uv_handle_t*', self))
end

function Handle:hasRef()
  return UV.uv_has_ref(cast('uv_handle_t*', self))
end

-------------------------------------------------------------------------------
-- Stream
-------------------------------------------------------------------------------

local Stream = setmetatable({}, {__index = Handle})

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

function Tcp:init(loop)
  return UV.uv_tcp_init(loop, self)
end

function Tcp:getsockname()
end

function Tcp:getpeername()
end


function Tcp:connect(host, port, callback)
  local req = ffi.new 'uv_connect_t'
  local addr = ffi.new 'struct sockaddr_in'
  UV.uv_ip4_addr(host, port, addr)
  local thread = coroutine.running()
  local cb
  local function onConnect(_, status)
    cb:free()
    if status == 0 then
      collectgarbage()
      coroutine.resume(thread, true)
      collectgarbage()
    else
      collectgarbage()
      local error = ffi.string(UV.uv_err_name(status)) .. ': ' .. ffi.string(UV.uv_strerror(status))
      collectgarbage()
      coroutine.resume(thread, false, error)
      collectgarbage()
    end
  end
  cb = ffi.cast('uv_connect_cb', onConnect)
  UV.uv_tcp_connect(req, self, addr, cb)
  return assert(coroutine.yield())
end

ffi.metatype(Tcp.type, {__index = Tcp})

-------------------------------------------------------------------------------
-- Timer
-------------------------------------------------------------------------------

ffi.cdef [[
  int uv_timer_init(uv_loop_t* loop, uv_timer_t* handle);
  int uv_timer_start(uv_timer_t* handle, uv_timer_cb cb, uint64_t timeout, uint64_t repeat);
  int uv_timer_stop(uv_timer_t* handle);
  int uv_timer_again(uv_timer_t* handle);
  void uv_timer_set_repeat(uv_timer_t* handle, uint64_t repeat);
  uint64_t uv_timer_get_repeat(const uv_timer_t* handle);
]]

local Timer = setmetatable({}, {__index = Handle})
Timer.type = ffi.typeof 'uv_timer_t'

function Timer:init(loop)
  return UV.uv_timer_init(loop, self)
end

function Timer:start(callback, timeout, rep)
  return UV.uv_timer_start(self, callback, timeout, rep)
end

function Timer:stop()
  return UV.uv_timer_stop(self)
end

function Timer:again()
  return UV.uv_timer_again(self)
end

function Timer:setRepeat(rep)
  return UV.uv_timer_set_repeat(self, rep)
end

function Timer:getRepeat()
  return UV.uv_timer_get_repeat(self)
end

ffi.metatype(Timer.type, {__index = Timer})

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
Loop.type = ffi.typeof 'uv_loop_t'

function Loop:newTimer()
  local timer = Timer.type()
  timer:init(self)
  return timer
end

function Loop:newTcp()
  local tcp = Tcp.type()
  tcp:init(self)
  return tcp
end

function Loop:init()
  return UV.uv_loop_init(self)
end

function Loop:close()
  return UV.uv_loop_close(self)
end

function Loop:alive()
  return UV.uv_loop_alive(self)
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
  return UV.uv_walk(self, callback, nil)
end

function Loop:run(mode)
  mode = assert(UV['UV_RUN_' .. mode], 'Unknown run mode')
  return UV.uv_run(self, mode)
end

ffi.metatype(Loop.type, {__index = Loop})

-------------------------------------------------------------------------------

return function()
  local loop = Loop.type()
  loop:init()
  return loop
end
