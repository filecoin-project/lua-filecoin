local Varint = require './varint'

local function identity()
  return function (message) return message end
end

local function sha1()
  local hexDecode = require('hex').decode
  local hash = require 'sha1'
  return function (message)
    return hexDecode(hash(message))
  end
end

local function sha256()
  return require('sha256')[256]
end

local function sha512()
  return require('sha512')[512]
end

local function blake2b(size)
  local ffi = require 'ffi'
  local rshift = require'bit'.rshift
  local hash = require 'blake2b'.hash
  local outlen = rshift(size, 3)
  return function (message)
    return ffi.string(hash(message, outlen), outlen)
  end
end

local function blake2s(size)
  local ffi = require 'ffi'
  local rshift = require'bit'.rshift
  local hash = require 'blake2s'.hash
  local outlen = rshift(size, 3)
  return function (message)
    return ffi.string(hash(message, outlen), outlen)
  end
end

local table = {
  {'identity',         0, identity},
  {'sha1',          0x11, sha1},
  {'sha2-256',      0x12, sha256},
  {'sha2-512',      0x13, sha512},
  {"blake2b-8",   0xb201, blake2b,   8},
  {"blake2b-16",  0xb202, blake2b,  16},
  {"blake2b-24",  0xb203, blake2b,  24},
  {"blake2b-32",  0xb204, blake2b,  32},
  {"blake2b-40",  0xb205, blake2b,  40},
  {"blake2b-48",  0xb206, blake2b,  48},
  {"blake2b-56",  0xb207, blake2b,  56},
  {"blake2b-64",  0xb208, blake2b,  64},
  {"blake2b-72",  0xb209, blake2b,  72},
  {"blake2b-80",  0xb20a, blake2b,  80},
  {"blake2b-88",  0xb20b, blake2b,  88},
  {"blake2b-96",  0xb20c, blake2b,  96},
  {"blake2b-104", 0xb20d, blake2b, 104},
  {"blake2b-112", 0xb20e, blake2b, 112},
  {"blake2b-120", 0xb20f, blake2b, 120},
  {"blake2b-128", 0xb210, blake2b, 128},
  {"blake2b-136", 0xb211, blake2b, 136},
  {"blake2b-144", 0xb212, blake2b, 144},
  {"blake2b-152", 0xb213, blake2b, 152},
  {"blake2b-160", 0xb214, blake2b, 160},
  {"blake2b-168", 0xb215, blake2b, 168},
  {"blake2b-176", 0xb216, blake2b, 176},
  {"blake2b-184", 0xb217, blake2b, 184},
  {"blake2b-192", 0xb218, blake2b, 192},
  {"blake2b-200", 0xb219, blake2b, 200},
  {"blake2b-208", 0xb21a, blake2b, 208},
  {"blake2b-216", 0xb21b, blake2b, 216},
  {"blake2b-224", 0xb21c, blake2b, 224},
  {"blake2b-232", 0xb21d, blake2b, 232},
  {"blake2b-240", 0xb21e, blake2b, 240},
  {"blake2b-248", 0xb21f, blake2b, 248},
  {"blake2b-256", 0xb220, blake2b, 256},
  {"blake2b-264", 0xb221, blake2b, 264},
  {"blake2b-272", 0xb222, blake2b, 272},
  {"blake2b-280", 0xb223, blake2b, 280},
  {"blake2b-288", 0xb224, blake2b, 288},
  {"blake2b-296", 0xb225, blake2b, 296},
  {"blake2b-304", 0xb226, blake2b, 304},
  {"blake2b-312", 0xb227, blake2b, 312},
  {"blake2b-320", 0xb228, blake2b, 320},
  {"blake2b-328", 0xb229, blake2b, 328},
  {"blake2b-336", 0xb22a, blake2b, 336},
  {"blake2b-344", 0xb22b, blake2b, 344},
  {"blake2b-352", 0xb22c, blake2b, 352},
  {"blake2b-360", 0xb22d, blake2b, 360},
  {"blake2b-368", 0xb22e, blake2b, 368},
  {"blake2b-376", 0xb22f, blake2b, 376},
  {"blake2b-384", 0xb230, blake2b, 384},
  {"blake2b-392", 0xb231, blake2b, 392},
  {"blake2b-400", 0xb232, blake2b, 400},
  {"blake2b-408", 0xb233, blake2b, 408},
  {"blake2b-416", 0xb234, blake2b, 416},
  {"blake2b-424", 0xb235, blake2b, 424},
  {"blake2b-432", 0xb236, blake2b, 432},
  {"blake2b-440", 0xb237, blake2b, 440},
  {"blake2b-448", 0xb238, blake2b, 448},
  {"blake2b-456", 0xb239, blake2b, 456},
  {"blake2b-464", 0xb23a, blake2b, 464},
  {"blake2b-472", 0xb23b, blake2b, 472},
  {"blake2b-480", 0xb23c, blake2b, 480},
  {"blake2b-488", 0xb23d, blake2b, 488},
  {"blake2b-496", 0xb23e, blake2b, 496},
  {"blake2b-504", 0xb23f, blake2b, 504},
  {"blake2b-512", 0xb240, blake2b, 512},
  {"blake2s-8",   0xb241, blake2s,   8},
  {"blake2s-16",  0xb242, blake2s,  16},
  {"blake2s-24",  0xb243, blake2s,  24},
  {"blake2s-32",  0xb244, blake2s,  32},
  {"blake2s-40",  0xb245, blake2s,  40},
  {"blake2s-48",  0xb246, blake2s,  48},
  {"blake2s-56",  0xb247, blake2s,  56},
  {"blake2s-64",  0xb248, blake2s,  64},
  {"blake2s-72",  0xb249, blake2s,  72},
  {"blake2s-80",  0xb24a, blake2s,  80},
  {"blake2s-88",  0xb24b, blake2s,  88},
  {"blake2s-96",  0xb24c, blake2s,  96},
  {"blake2s-104", 0xb24d, blake2s, 104},
  {"blake2s-112", 0xb24e, blake2s, 112},
  {"blake2s-120", 0xb24f, blake2s, 120},
  {"blake2s-128", 0xb250, blake2s, 128},
  {"blake2s-136", 0xb251, blake2s, 136},
  {"blake2s-144", 0xb252, blake2s, 144},
  {"blake2s-152", 0xb253, blake2s, 152},
  {"blake2s-160", 0xb254, blake2s, 160},
  {"blake2s-168", 0xb255, blake2s, 168},
  {"blake2s-176", 0xb256, blake2s, 176},
  {"blake2s-184", 0xb257, blake2s, 184},
  {"blake2s-192", 0xb258, blake2s, 192},
  {"blake2s-200", 0xb259, blake2s, 200},
  {"blake2s-208", 0xb25a, blake2s, 208},
  {"blake2s-216", 0xb25b, blake2s, 216},
  {"blake2s-224", 0xb25c, blake2s, 224},
  {"blake2s-232", 0xb25d, blake2s, 232},
  {"blake2s-240", 0xb25e, blake2s, 240},
  {"blake2s-248", 0xb25f, blake2s, 248},
  {"blake2s-256", 0xb260, blake2s, 256},
}

local hashes = {}
local codes = {}
local names = {}
for i = 1, #table do
  local name, code, fn, size = unpack(table[i])
  hashes[name] = { fn, size }
  hashes[code] = hashes[name]
  codes[name] = code
  codes[code] = code
  names[name] = name
  names[code] = name
end

local function getHash(nameOrCode)
  local hash = assert(hashes[nameOrCode], "Unknown name or code")
  if type(hash) == 'table' then
    hash = hash[1](hash[2])
    hashes[nameOrCode] = hash
  end
  return hash
end

local function encode(digest, nameOrCode)
  local length = #digest
  local code = assert(codes[nameOrCode], "Unknown name or code")
  return Varint.encode(code) .. Varint.encode(length) .. digest, names[code]
end

local function hash(raw, nameOrCode, length)
  local hashfn = getHash(nameOrCode)
  local digest = hashfn(raw)
  local len = #digest
  if not length then length = len end
  assert(length <= len, "Specified length longer than natural digest length")
  if length < len then
    digest = digest:sub(1, length)
  end
  return encode(digest, nameOrCode)
end

local function decode(multi, index)
  index = index or 1
  local code, length
  code, index = Varint.decode(multi, index)
  length, index = Varint.decode(multi, index)
  local last = index + length - 1
  assert(#multi >= last)
  return multi:sub(index, last), names[code], index
end

local function verify(raw, multi, index)
  index = index or 1
  local code, length
  code, index = Varint.decode(multi, index)
  length, index = Varint.decode(multi, index)
  return multi == hash(raw, code, length), index
end

return {
  getHash = getHash,
  encode = encode,
  decode = decode,
  hash = hash,
  verify = verify,
}