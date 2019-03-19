local ffi = require 'ffi'

ffi.cdef [[
  struct in_addr {
    unsigned long s_addr;  // load with inet_aton()
  };

  struct sockaddr_in {
    short            sin_family;   // e.g. AF_INET
    unsigned short   sin_port;     // e.g. htons(3490)
    struct in_addr   sin_addr;     // see struct in_addr, above
    char             sin_zero[8];  // zero this if you want to
  };

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

  size_t uv_handle_size(uv_handle_type type);

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

  size_t uv_req_size(uv_req_type type);

  typedef struct uv_loop_s uv_loop_t;
  typedef struct uv_handle_s uv_handle_t;
  typedef struct uv_stream_s uv_stream_t;
  typedef struct uv_tcp_s uv_tcp_t;

  typedef struct uv_connect_s uv_connect_t;
  typedef struct uv_write_s uv_write_t;
  typedef struct uv_shutdown_s uv_shutdown_t;

  typedef void (*uv_close_cb)(uv_handle_t* handle);
  typedef void (*uv_connect_cb)(uv_connect_t* req, int status);

  int uv_is_closing(const uv_handle_t* handle);
  void uv_close(uv_handle_t* handle, uv_close_cb close_cb);

  int uv_ip4_addr(const char* ip, int port, struct sockaddr_in* addr);

  int uv_tcp_init(uv_loop_t* loop, uv_tcp_t* handle);
  int uv_tcp_bind(uv_tcp_t* handle, const struct sockaddr* addr, unsigned int flags);
  int uv_tcp_connect(uv_connect_t* req, uv_tcp_t* handle, const struct sockaddr* addr, uv_connect_cb cb);
]]
local newBuffer = ffi.typeof('uint8_t[?]')
local Tcp = ffi.typeof('uv_tcp_t*')
local TcpSize = ffi.C.uv_handle_size(ffi.C.UV_TCP)
local Connect = ffi.typeof('uv_connect_t*')
local ConnectSize = ffi.C.uv_req_size(ffi.C.UV_CONNECT)

local tcp = ffi.cast(Tcp, newBuffer(TcpSize))
p(tcp)
local addr = ffi.new('struct sockaddr_in')
ffi.C.uv_ip4_addr('127.0.0.1', 3000, addr)
local req = ffi.cast(Connect, newBuffer(ConnectSize))
p(req)
ffi.C.uv_tcp_connect()