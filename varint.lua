local char = string.char
local byte = string.byte
local unpack = table.unpack or unpack
local bit = require 'bit'
local bor = bit.bor
local band = bit.band
local lshift = bit.lshift
local rshift = bit.rshift

local Varint = {}

function Varint.decode(chunk, index)
  local length = 0
  local bits = 0
  while true do
    local b = byte(chunk, index)
    index = index + 1
    length = bor(length, lshift(band(b, 0x7f), bits))
    if b < 0x80 then
      break
    end
    bits = bits + 7
  end
  return length, index
end

function Varint.decodebin(chunk, offset)
  local length = 0
  local bits = 0
  while true do
    local b = chunk[offset]
    offset = offset + 1
    length = bor(length, lshift(band(b, 0x7f), bits))
    if b < 0x80 then
      break
    end
    bits = bits + 7
  end
  return length, offset
end

function Varint.encode(num)
  local parts = {}
  while num >= 0x80 do
    parts[#parts + 1] = bor(band(num, 0x7f), 0x80)
    num = rshift(num, 7)
  end
  parts[#parts + 1] = num
  return char(unpack(parts))
end

local encode = Varint.encode

function Varint.read(stream)
  -- Parse the varint length header first.
  local length = 0
  local bits = 0
  while true do
    local b = stream.readByte()
    if not b then
      return
    end
    length = bor(length, lshift(band(b, 0x7f), bits))
    if b < 0x80 then
      break
    end
    bits = bits + 7
  end
  return length
end

local read = Varint.read

function Varint.readFrame(stream)
  local length = read(stream)
  if not length then
    return
  end
  return stream.readChunk(length)
end

function Varint.write(stream, value)
  return stream.writeChunk(encode(value))
end

function Varint.writeFrame(stream, message)
  stream.writeChunk(encode(#message) .. message)
end

return Varint
