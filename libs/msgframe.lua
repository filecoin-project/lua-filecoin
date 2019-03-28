local bit = require 'bit'
local bor = bit.bor
local band = bit.band
local lshift = bit.lshift
local rshift = bit.rshift
local byte = string.byte
local char = string.char

-- Frame/deframe messages with simple uint32 headers.

local Msg = {}

local function readUint32(data)
  return bor(
    lshift(byte(data, 1), 24),
    lshift(byte(data, 2), 16),
    lshift(byte(data, 3), 8),
    byte(data, 4)
  )
end

local function encodeUint32(length)
  return char(
    band(0xff, rshift(length, 24)),
    band(0xff, rshift(length, 16)),
    band(0xff, rshift(length, 8)),
    band(0xff, length)
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
