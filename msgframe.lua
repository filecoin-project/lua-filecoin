local byte = string.byte
local char = string.char

-- Frame/deframe messages with simple uint32 headers.

local Msg = {}

local function readUint32(data)
  return (byte(data, 1) << 24)
       | (byte(data, 2) << 16)
       | (byte(data, 3) << 8)
       |  byte(data, 4)
end

local function encodeUint32(length)
  return char(
    (0xff & (length >> 24)),
    (0xff & (length >> 16)),
    (0xff & (length >> 8)),
    (0xff & length)
  )
end

function Msg.writeFrame(stream, message)
  return stream.writeChunk(encodeUint32(#message) .. message)
end

function Msg.readFrame(stream)
  local length = readUint32(stream.readChunk(4))
  return stream.readChunk(length)
end

return Msg
