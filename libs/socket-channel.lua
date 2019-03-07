local makeCallback = require "make-callback"
local ffi = require "ffi"
local newBuffer = ffi.typeof("uint8_t[?]")
local sub = string.sub
local byte = string.byte

return function(socket)
    -- Chunk and index store the current buffered input from libuv
    local chunk = ""
    local size = 0
    local index = 1
    -- If libuv reported an error onRead, it's stored here
    local errored = false
    -- If libuv reported EOS, this will be true
    local ended = false
    -- Flag to know the paused state of libuv's stream
    local paused = true
    -- When there is a waiting reader, this is it's coroutine
    local thread = nil

    local function consume()
        if index <= size then
            local b = byte(chunk, index)
            index = index + 1
            if index > size then
                chunk = ""
                index = 1
                size = 0
            end
            return b
        end
        assert(errored or ended)
        return nil, errored
    end

    local function onRead(err, result)
        if err then
            errored = err
        elseif result then
            if index <= size then
                chunk = sub(chunk, index) .. result
                if not paused then
                    paused = true
                    socket:read_stop()
                end
            else
                chunk = result
            end
            index = 1
            size = #chunk
        else
            ended = true
        end

        if thread and index <= size then
            local t = thread
            thread = nil
            assert(coroutine.resume(t, consume()))
        end
    end

    local function next()
        if index <= size then
            return consume()
        end
        if paused then
            paused = false
            socket:read_start(onRead)
        end
        assert(not thread, "Concurrent reads on same socket not allowed")
        thread = coroutine.running()
        return coroutine.yield()
    end

    local function read(numBytes)
        local buffer = newBuffer(numBytes)
        for i = 0, numBytes - 1 do
            local b, err = next()
            if not b then
                return nil, err
            end
            buffer[i] = b
        end
        return ffi.string(buffer, numBytes)
    end

    local function write(value)
        socket:write(value, makeCallback())
        local err = coroutine.yield()
        return not err, err
    end

    return {
        next = next,
        read = read,
        write = write,
        socket = socket
    }
end
