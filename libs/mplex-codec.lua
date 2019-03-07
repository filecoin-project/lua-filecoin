local varint = require "varint-codec"

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

local function encode(message)
    local flag = assert(flags[assert(message[1])])
    local id = assert(message[2])
    local body = assert(message[3])
    return varint.encode(varint.write(flag + id * 8) .. body)
end

local function decode()
end

return {
    flags = flags,
    encode = encode,
    decode = decode
}
