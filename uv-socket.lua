local uv = require "luv"
local makeCallback = require "make-callback"

local function normalize(options)
    local t = type(options)
    if t == "string" then
        options = {path = options}
    elseif t == "number" then
        options = {port = options}
    elseif t ~= "table" then
        assert("Net options must be table, string, or number")
    end
    if options.port or options.host then
        options.isTcp = true
        options.host = options.host or "127.0.0.1"
        assert(options.port, "options.port is required for tcp connections")
    elseif options.path then
        options.isTcp = false
    else
        error("Must set either options.path or options.port")
    end
    return options
end

return function(options)
    local socket, success, err
    options = normalize(options)
    if options.isTcp then
        success, err =
            uv.getaddrinfo(
            options.host,
            options.port,
            {
                socktype = options.socktype or "stream",
                family = options.family or "inet"
            },
            makeCallback()
        )
        if not success then
            return nil, err
        end
        local res
        res, err = coroutine.yield()
        if not res then
            return nil, err
        end
        socket = uv.new_tcp()
        socket:connect(res[1].addr, res[1].port, makeCallback())
    else
        socket = uv.new_pipe(false)
        socket:connect(options.path, makeCallback())
    end
    success, err = coroutine.yield()
    if not success then
        return nil, err
    end
    return socket
end