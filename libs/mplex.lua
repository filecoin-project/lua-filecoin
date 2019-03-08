local varint = require "varint"

local flags = {
    [0] = "NewStream",
    [1] = "MessageReceiver",
    [2] = "MessageInitiator",
    [3] = "CloseReceiver",
    [4] = "CloseInitiator",
    [5] = "ResetReceiver",
    [6] = "ResetInitiator",
    NewStream = 0,
    MessageReceiver = 1,
    MessageInitiator = 2,
    CloseReceiver = 3,
    CloseInitiator = 4,
    ResetReceiver = 5,
    ResetInitiator = 6
}

local function write(socket, flag, id, body)
    assert(type(flag) == "string")
    assert(type(id) == "number")
    assert(type(body) == "string")
    local message = varint.encode(flags[flag] + id * 8) .. body
    return socket.write(varint.encode(#message) .. message)
end

return {
    flags = flags,
    write = write
}
