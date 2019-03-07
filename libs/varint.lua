local bit = require "bit"
local band = bit.band
local bor = bit.bor
local rshift = bit.rshift
local lshift = bit.lshift
local char = string.char

local function read(next)
    local length = 0
    while true do
        local b, err = next()
        if not b then
            return nil, err
        end
        length = bor(length, band(b, 0x7f))
        if b < 0x80 then
            break
        end
        length = lshift(length, 7)
    end
    return length
end

local function write(num)
    local parts = {}
    while num > 0x80 do
        parts[#parts + 1] = bor(band(num, 0x7f), 0x80)
        num = rshift(num, 7)
    end
    parts[#parts + 1] = num
    return char(unpack(parts))
end

return {
    write = write,
    read = read
}
