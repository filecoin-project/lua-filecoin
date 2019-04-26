--[[lit-meta
  name = "creationix/blake2b"
  version = "1.0.1"
  homepage = "https://github.com/creationix/luajit-blake2b"
  description = "Pure luajit implementation of blake2b."
  tags = {"hash", "blake2", "ffi", "luajit"}
  license = "MIT"
  author = { name = "Tim Caswell" }
]]

local bit = require 'bit'
local ffi = require 'ffi'
local ror = bit.ror
local lshift = bit.lshift
local rshift = bit.rshift
local bxor = bit.bxor
local band = bit.band
local bor = bit.bor
local bnot = bit.bnot
local format = string.format
local concat = table.concat
local copy = ffi.copy
local fill = ffi.fill
local sizeof = ffi.sizeof

ffi.cdef[[
  typedef struct {
    uint8_t b[128]; // input buffer
    uint64_t h[8];  // chained state
    uint64_t t[2];  // total number of bytes
    size_t c;       // pointer for b[]
    size_t outlen;  // digest size
  } blake2b_ctx;
]]

local buffer = ffi.typeof 'uint8_t[?]'
local u64 = ffi.typeof 'uint64_t'

local IV = ffi.new('uint64_t[8]', {
  0x6A09E667F3BCC908ULL, 0xBB67AE8584CAA73BULL,
  0x3C6EF372FE94F82BULL, 0xA54FF53A5F1D36F1ULL,
  0x510E527FADE682D1ULL, 0x9B05688C2B3E6C1FULL,
  0x1F83D9ABFB41BD6BULL, 0x5BE0CD19137E2179ULL,
})

local sigma = ffi.new('uint8_t[12][16]', {
  { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
  { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
  { 11, 8, 12, 0, 5, 2, 15, 13, 10, 14, 3, 6, 7, 1, 9, 4 },
  { 7, 9, 3, 1, 13, 12, 11, 14, 2, 6, 5, 10, 4, 0, 15, 8 },
  { 9, 0, 5, 7, 2, 4, 10, 15, 14, 1, 11, 12, 6, 8, 3, 13 },
  { 2, 12, 6, 10, 0, 11, 8, 3, 4, 13, 7, 5, 15, 14, 1, 9 },
  { 12, 5, 1, 15, 14, 13, 4, 10, 0, 7, 6, 3, 9, 2, 8, 11 },
  { 13, 11, 7, 14, 12, 1, 3, 9, 5, 0, 15, 4, 8, 6, 2, 10 },
  { 6, 15, 14, 9, 11, 3, 0, 8, 12, 2, 13, 7, 1, 4, 10, 5 },
  { 10, 2, 8, 4, 7, 6, 1, 5, 15, 11, 9, 14, 3, 12, 13, 0 },
  { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15 },
  { 14, 10, 4, 8, 9, 15, 13, 6, 1, 12, 0, 2, 11, 7, 5, 3 },
})

-- Little-endian byte access.
local function get64(ptr)
  return bor(
    u64(ptr[0]),
    lshift(u64(ptr[1]), 8),
    lshift(u64(ptr[2]), 16),
    lshift(u64(ptr[3]), 24),
    lshift(u64(ptr[4]), 32),
    lshift(u64(ptr[5]), 40),
    lshift(u64(ptr[6]), 48),
    lshift(u64(ptr[7]), 56)
  )
end

local new_ctx

-- local function dump(header, data, w)
--   io.write(header)
--   for i = 0, w - 1 do
--     io.write(format(' %08X%08X',
--       tonumber(rshift(data[i], 32)),
--       tonumber(band(data[i], 0xffffffffULL))
--     ))
--     if i % 3 == 2 then
--       io.write '\n               '
--     end
--   end
--   io.write '\n\n'
-- end

local v = ffi.new 'uint64_t[16]'
local m = ffi.new 'uint64_t[16]'

-- Mixing function G.
local function G(a, b, c, d, x, y)
    v[a] = v[a] + v[b] + x
    v[d] = ror(bxor(v[d], v[a]), 32)
    v[c] = v[c] + v[d]
    v[b] = ror(bxor(v[b], v[c]), 24)
    v[a] = v[a] + v[b] + y
    v[d] = ror(bxor(v[d], v[a]), 16)
    v[c] = v[c] + v[d]
    v[b] = ror(bxor(v[b], v[c]), 63)
end

local function ROUND(i)
  -- dump(string.format(' (i=%02d) v[16] =', i), v, 16)
  G(0, 4,  8, 12, m[sigma[i][ 0]], m[sigma[i][ 1]])
  -- dump(string.format(' (i=%02d)    v1 =', i), v, 16)
  G(1, 5,  9, 13, m[sigma[i][ 2]], m[sigma[i][ 3]])
  -- dump(string.format(' (i=%02d)    v2 =', i), v, 16)
  G(2, 6, 10, 14, m[sigma[i][ 4]], m[sigma[i][ 5]])
  -- dump(string.format(' (i=%02d)    v3 =', i), v, 16)
  G(3, 7, 11, 15, m[sigma[i][ 6]], m[sigma[i][ 7]])
  -- dump(string.format(' (i=%02d)    v4 =', i), v, 16)
  G(0, 5, 10, 15, m[sigma[i][ 8]], m[sigma[i][ 9]])
  -- dump(string.format(' (i=%02d)    v5 =', i), v, 16)
  G(1, 6, 11, 12, m[sigma[i][10]], m[sigma[i][11]])
  -- dump(string.format(' (i=%02d)    v6 =', i), v, 16)
  G(2, 7,  8, 13, m[sigma[i][12]], m[sigma[i][13]])
  -- dump(string.format(' (i=%02d)    v7 =', i), v, 16)
  G(3, 4,  9, 14, m[sigma[i][14]], m[sigma[i][15]])
  -- dump(string.format(' (i=%02d)    v8 =', i), v, 16)
end

local Blake2b = {}

function Blake2b:compress(is_last)

  for i = 0, 7 do -- init work variables
    v[i] = self.h[i]
    v[i + 8] = IV[i]
  end

  v[12] = bxor(v[12], self.t[0]) -- low 32 bits of offset
  v[13] = bxor(v[13], self.t[1]) -- high 32 bits

  if is_last then -- last block flag set ?
    v[14] = bnot(v[14])
  end

  for i = 0, 15 do -- get little-endian 64-bit words
    m[i] = get64(self.b + 8 * i)
  end

  -- dump('        m[16] =', m, 16)

  for i = 0, 11 do -- twelve rounds
    ROUND(i)
  end

  -- dump(' (i=12) v[16] =', v, 16)

  for i = 0, 7 do
    self.h[i] = bxor(self.h[i], v[i], v[i + 8])
  end

  -- dump('         h[8] =', self.h, 8)

end

function Blake2b.new(outlen, key)
  if not outlen then outlen = 64 end
  assert(type(outlen) == 'number' and outlen > 0 and outlen <= 64)
  if type(key) == 'string' then
    local str = key
    local len = #str
    key = buffer(#key)
    copy(key, str, len)
  end
  local keylen = key and sizeof(key) or 0

  local ctx = new_ctx()

  copy(ctx.h, IV, sizeof(IV)) -- state, "param block"

  ctx.h[0] = bxor(ctx.h[0], 0x01010000, lshift(keylen, 8), outlen)
  ctx.t[0] = 0 -- input count low word
  ctx.t[1] = 0 -- input count high word
  ctx.c = 0    -- pointer within buffer
  ctx.outlen = outlen

  if keylen > 0 then
      ctx:update(key)
      ctx.c = 128 -- at the end
  end

  return ctx
end

function Blake2b:update(input)
  if type(input) == 'string' then
    local str = input
    local len = #str
    input = buffer(len)
    copy(input, str, len)
  end

  for i = 0, sizeof(input) - 1 do
    if self.c == 128 then
      self.t[0] = self.t[0] + self.c
      if self.t[0] < self.c then
        self.t[1] = self.t[1] + 1
      end
      self.c = 0
      self:compress(false)
    end
    self.b[self.c] = input[i]
    self.c = self.c + 1
  end
end

function Blake2b:digest(form)
  self.t[0] = self.t[0] + self.c
  if self.t[0] < self.c then
    self.t[1] = self.t[1] + 1
  end


  if self.c < 128 then -- fill up with zeros
    fill(self.b + self.c, 128 - self.c)
  end

  self:compress(true)

  -- little endian convert and store
  local out = buffer(self.outlen)
  for i = 0, tonumber(self.outlen) - 1 do
    out[i] = rshift(self.h[rshift(i, 3)], 8 * band(i, 7))
  end

  if form == 'string' then
    return ffi.string(out, self.outlen)
  end
  if form == 'hex' then
    local hex = {}
    for i = 1, tonumber(self.outlen) do
      hex[i] = format("%02x", out[i - 1])
    end
    return concat(hex)
  end
  return out
end

function Blake2b.hash(data, outlen, key, form)
  local h = Blake2b.new(outlen, key)
  h:update(data)
  return h:digest(form)
end

new_ctx = ffi.metatype('blake2b_ctx', { __index = Blake2b })

return Blake2b
