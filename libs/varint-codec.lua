local bit = require "bit"
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local char = string.char
local byte = string.byte
local sub = string.sub

local function encode(line)
    line = line .. "\n"
    local length = #line
    local parts = {}
    while length > 0x80 do
        parts[#parts + 1] = bor(band(length, 0x7f), 0x80)
        length = rshift(length, 7)
    end
    parts[#parts + 1] = length
    line = char(unpack(parts)) .. line
    return line
end

local function decode(chunk, index)
    local length = 0
    local i = index
    local len = #chunk
    while true do
        if i > len then
            return
        end
        local b = byte(chunk, i)
        i = i + 1
        length = bor(length, band(b, 0x7f))
        if b < 0x80 then
            break
        end
        length = lshift(length, 7)
    end
    local last = i + length - 1
    if len < last then
        return
    end
    local value = sub(chunk, i, last - 1)
    return value, last + 1
end

return {
    encode = encode,
    decode = decode
}
