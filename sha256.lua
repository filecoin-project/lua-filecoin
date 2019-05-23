local bit = require 'bit'
local ffi = require 'ffi'
local ror = bit.ror
local bxor = bit.bxor
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot
local tobit = bit.tobit
local rshift = bit.rshift
local lshift = bit.lshift
local char = string.char
local concat = table.concat

local initial224 = ffi.new('uint32_t[8]', {
  0xc1059ed8, 0x367cd507, 0x3070dd17, 0xf70e5939, 0xffc00b31, 0x68581511, 0x64f98fa7, 0xbefa4fa4,
})

local initial256 = ffi.new('uint32_t[8]', {
  0x6a09e667, 0xbb67ae85, 0x3c6ef372, 0xa54ff53a, 0x510e527f, 0x9b05688c, 0x1f83d9ab, 0x5be0cd19,
})

local k256 = ffi.new('uint32_t[64]', {
  0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5, 0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
  0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3, 0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
  0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc, 0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
  0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7, 0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
  0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13, 0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
  0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3, 0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
  0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5, 0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
  0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208, 0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2,
})

ffi.cdef [[
  struct state256 {
    uint32_t h[8];
    uint32_t w[64];
    intptr_t offset;
    size_t length;
    size_t digestLength;
  };
]]

local function uint32(num)
  return char(
    rshift(num,  24),
    band(rshift(num,  16), 0xff),
    band(rshift(num,  8), 0xff),
    band(num,  0xff)
  )
end

local Sha256 = {}

function Sha256:init()
  self.offset = 0
  self.length = 0
  self.digestLength = 32
  ffi.copy(self.h, initial256, 32)
end

function Sha256:init224()
  self.offset = 0
  self.length = 0
  self.digestLength = 28
  ffi.copy(self.h, initial224, 32)
end

function Sha256:update(message)
  local length = #message
  self.length = self.length + length
  local input = ffi.new("uint8_t[?]", length)
  ffi.copy(input, message, length)
  local offset = 0
  while offset < length do
    local needed = length - offset
    local available = tonumber(64 - self.offset)
    local slice = math.min(needed, available)
    for _ = 1, slice do
      local j = rshift(self.offset, 2)
      local mod = self.offset % 4
      if mod == 0 then self.w[j] = 0 end
      self.w[j] = bor(self.w[j], lshift(input[offset], (3 - mod) * 8))
      offset = offset + 1
      self.offset = self.offset + 1
    end
    assert(self.offset <= 64)
    if self.offset == 64 then
      self:compress()
    end
  end
end

function Sha256:compress()
  -- p(ffi.string(self.w, 64))
  -- Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
  for i = 16, 63 do
    local s0 = bxor(ror(self.w[i - 15],  7), ror(self.w[i - 15], 18), rshift(self.w[i - 15],  3))
    local s1 = bxor(ror(self.w[i -  2], 17), ror(self.w[i -  2], 19), rshift(self.w[i -  2], 10))
    self.w[i] = self.w[i - 16] + s0 + self.w[i - 7] + s1
  end

  -- Initialize working variables to current hash value
  local a = self.h[0]
  local b = self.h[1]
  local c = self.h[2]
  local d = self.h[3]
  local e = self.h[4]
  local f = self.h[5]
  local g = self.h[6]
  local h = self.h[7]

  -- Compression function main loop
  for i = 0, 63 do
    local S1 = bxor(ror(e, 6), ror(e, 11), ror(e, 25))
    local ch = bxor(band(e, f), band(bnot(e), g))
    local temp1 = tobit(h + S1 + ch + k256[i] + self.w[i])
    local S0 = bxor(ror(a, 2), ror(a, 13), ror(a, 22))
    local maj = bxor(band(a, b), band(a, c), band(b, c))
    local temp2 = tobit(S0 + maj)
    h = g
    g = f
    f = e
    e = tobit(d + temp1)
    d = c
    c = b
    b = a
    a = tobit(temp1 + temp2)
  end

  -- Add the compressed chunk to the current hash value:
  self.h[0] = self.h[0] + a
  self.h[1] = self.h[1] + b
  self.h[2] = self.h[2] + c
  self.h[3] = self.h[3] + d
  self.h[4] = self.h[4] + e
  self.h[5] = self.h[5] + f
  self.h[6] = self.h[6] + g
  self.h[7] = self.h[7] + h

  -- Reset write offset
  self.offset = 0
end

function Sha256:pad()
  local L = self.length * 8
  local K = tonumber((128 - 8 - 1 - self.offset) % 64)
  local high = tonumber(L / 0x100000000)
  local low = tonumber(L % 0x100000000)
  self:update('\128' .. ('\000'):rep(K) .. uint32(high) .. uint32(low))
end

function Sha256:digest()
  self:pad()
  assert(self.offset == 0)
  local parts = {}
  for i = 0, tonumber(self.digestLength) / 4 - 1 do
    parts[i + 1] = uint32(self.h[i])
  end
  return concat(parts)
end

local create = ffi.metatype('struct state256', {__index = Sha256})

return {
  [256] = function (message)
    local shasum = create()
    shasum:init()
    -- Pass in false or nil to get a streaming interface.
    if not message then
      return shasum
    end
    shasum:update(message)
    return shasum:digest()
  end,
  [224] = function (message)
    local shasum = create()
    shasum:init224()
    -- Pass in false or nil to get a streaming interface.
    if not message then
      return shasum
    end
    shasum:update(message)
    return shasum:digest()
  end,
}