local bit = require 'bit'
local ffi = require 'ffi'
local ror = bit.ror
local bxor = bit.bxor
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot
local rshift = bit.rshift
local lshift = bit.lshift
local char = string.char
local concat = table.concat

local initial384 = ffi.new('uint64_t[8]', {
  0xcbbb9d5dc1059ed8ULL, 0x629a292a367cd507ULL, 0x9159015a3070dd17ULL, 0x152fecd8f70e5939ULL,
  0x67332667ffc00b31ULL, 0x8eb44a8768581511ULL, 0xdb0c2e0d64f98fa7ULL, 0x47b5481dbefa4fa4ULL,
})

local initial512 = ffi.new('uint64_t[8]', {
  0x6a09e667f3bcc908ULL, 0xbb67ae8584caa73bULL, 0x3c6ef372fe94f82bULL, 0xa54ff53a5f1d36f1ULL,
  0x510e527fade682d1ULL, 0x9b05688c2b3e6c1fULL, 0x1f83d9abfb41bd6bULL, 0x5be0cd19137e2179ULL,
})

local k = ffi.new('uint64_t[80]', {
  0x428a2f98d728ae22ULL, 0x7137449123ef65cdULL, 0xb5c0fbcfec4d3b2fULL, 0xe9b5dba58189dbbcULL, 0x3956c25bf348b538ULL,
  0x59f111f1b605d019ULL, 0x923f82a4af194f9bULL, 0xab1c5ed5da6d8118ULL, 0xd807aa98a3030242ULL, 0x12835b0145706fbeULL,
  0x243185be4ee4b28cULL, 0x550c7dc3d5ffb4e2ULL, 0x72be5d74f27b896fULL, 0x80deb1fe3b1696b1ULL, 0x9bdc06a725c71235ULL,
  0xc19bf174cf692694ULL, 0xe49b69c19ef14ad2ULL, 0xefbe4786384f25e3ULL, 0x0fc19dc68b8cd5b5ULL, 0x240ca1cc77ac9c65ULL,
  0x2de92c6f592b0275ULL, 0x4a7484aa6ea6e483ULL, 0x5cb0a9dcbd41fbd4ULL, 0x76f988da831153b5ULL, 0x983e5152ee66dfabULL,
  0xa831c66d2db43210ULL, 0xb00327c898fb213fULL, 0xbf597fc7beef0ee4ULL, 0xc6e00bf33da88fc2ULL, 0xd5a79147930aa725ULL,
  0x06ca6351e003826fULL, 0x142929670a0e6e70ULL, 0x27b70a8546d22ffcULL, 0x2e1b21385c26c926ULL, 0x4d2c6dfc5ac42aedULL,
  0x53380d139d95b3dfULL, 0x650a73548baf63deULL, 0x766a0abb3c77b2a8ULL, 0x81c2c92e47edaee6ULL, 0x92722c851482353bULL,
  0xa2bfe8a14cf10364ULL, 0xa81a664bbc423001ULL, 0xc24b8b70d0f89791ULL, 0xc76c51a30654be30ULL, 0xd192e819d6ef5218ULL,
  0xd69906245565a910ULL, 0xf40e35855771202aULL, 0x106aa07032bbd1b8ULL, 0x19a4c116b8d2d0c8ULL, 0x1e376c085141ab53ULL,
  0x2748774cdf8eeb99ULL, 0x34b0bcb5e19b48a8ULL, 0x391c0cb3c5c95a63ULL, 0x4ed8aa4ae3418acbULL, 0x5b9cca4f7763e373ULL,
  0x682e6ff3d6b2b8a3ULL, 0x748f82ee5defb2fcULL, 0x78a5636f43172f60ULL, 0x84c87814a1f0ab72ULL, 0x8cc702081a6439ecULL,
  0x90befffa23631e28ULL, 0xa4506cebde82bde9ULL, 0xbef9a3f7b2c67915ULL, 0xc67178f2e372532bULL, 0xca273eceea26619cULL,
  0xd186b8c721c0c207ULL, 0xeada7dd6cde0eb1eULL, 0xf57d4f7fee6ed178ULL, 0x06f067aa72176fbaULL, 0x0a637dc5a2c898a6ULL,
  0x113f9804bef90daeULL, 0x1b710b35131c471bULL, 0x28db77f523047d84ULL, 0x32caab7b40c72493ULL, 0x3c9ebe0a15c9bebcULL,
  0x431d67c49c100d4cULL, 0x4cc5d4becb3e42b6ULL, 0x597f299cfc657e2aULL, 0x5fcb6fab3ad6faecULL, 0x6c44198c4a475817ULL,
})

ffi.cdef[[
  struct state512 {
    uint64_t h[8];
    uint64_t w[80];
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

local Sha512 = {}

function Sha512:init()
  self.offset = 0
  self.length = 0
  self.digestLength = 64
  ffi.copy(self.h, initial512, 64)
end

function Sha512:init384()
  self.offset = 0
  self.length = 0
  self.digestLength = 48
  ffi.copy(self.h, initial384, 64)
end

function Sha512:update(message)
  local length = #message
  self.length = self.length + length
  local input = ffi.new("uint8_t[?]", length)
  ffi.copy(input, message, length)
  local offset = 0
  while offset < length do
    local needed = length - offset
    local available = tonumber(128 - self.offset)
    local slice = math.min(needed, available)
    for _ = 1, slice do
      local j = rshift(self.offset, 3)
      local mod = self.offset % 8
      if mod == 0 then self.w[j] = 0 end
      self.w[j] = bor(self.w[j], lshift(1ULL * input[offset], (7 - mod) * 8))
      offset = offset + 1
      self.offset = self.offset + 1
    end
    assert(self.offset <= 128)
    if self.offset == 128 then
      self:compress()
    end
  end
end

function Sha512:compress()
  -- p(ffi.string(self.w, 128))
  -- Extend the first 16 words into the remaining 48 words w[16..63] of the message schedule array:
  for i = 16, 79 do
    local s0 = bxor(ror(self.w[i - 15],  1), ror(self.w[i - 15], 8), rshift(self.w[i - 15],  7))
    local s1 = bxor(ror(self.w[i -  2], 19), ror(self.w[i -  2], 61), rshift(self.w[i -  2], 6))
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
  for i = 0, 79 do
    local S1 = bxor(ror(e, 14), ror(e, 18), ror(e, 41))
    local ch = bxor(band(e, f), band(bnot(e), g))
    local temp1 = h + S1 + ch + k[i] + self.w[i]
    local S0 = bxor(ror(a, 28), ror(a, 34), ror(a, 39))
    local maj = bxor(band(a, b), band(a, c), band(b, c))
    local temp2 = S0 + maj
    h = g
    g = f
    f = e
    e = d + temp1
    d = c
    c = b
    b = a
    a = temp1 + temp2
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

function Sha512:pad()
  local L = self.length * 8
  local K = tonumber((256 - 16 - 1 - self.offset) % 128) + 8
  local high = tonumber(L / 0x100000000)
  local low = tonumber(L % 0x100000000)
  self:update('\128' .. ('\000'):rep(K) .. uint32(high) .. uint32(low))
end

function Sha512:digest()
  self:pad()
  assert(self.offset == 0)
  local parts = {}
  for i = 1, tonumber(self.digestLength) / 8 do
    local h = self.h[i - 1]
    local high = tonumber(h / 0x100000000)
    local low = tonumber(h % 0x100000000)
    parts[i] = uint32(high) .. uint32(low)
  end
  return concat(parts)
end

local create = ffi.metatype('struct state512', {__index = Sha512})

return {
  [512] = function (message)
    local shasum = create()
    shasum:init()
    if not message then return shasum end
    shasum:update(message)
    return shasum:digest()
  end,
  [384] = function (message)
    local shasum = create()
    shasum:init384()
    if not message then return shasum end
    shasum:update(message)
    return shasum:digest()
  end,
}