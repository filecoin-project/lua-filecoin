local baseX = require 'base-x'
local base2 = require 'base-2'
local base16 = require 'base-16'
local base32 = require 'base-32'
local base64 = require 'base-64'

local function identity()
  local function passthrough(message) return message end
  return {
    encode = passthrough,
    decode = passthrough
  }
end

local table = {
  {'identity',    '\0', identity, ''},
  {'base2',        '0', base2,  '01'},
  {'base8',        '7', baseX,  '01234567'},
  {'base10',       '9', baseX,  '0123456789'},
  {'base16',       'f', base16, '0123456789abcdef'},
  {'base16upper',  'F', base16, '0123456789ABCDEF'},
  {'base32',       'b', base32, 'abcdefghijklmnopqrstuvwxyz234567'},
  {'base32pad',    'c', base32, 'abcdefghijklmnopqrstuvwxyz234567='},
  {'base32hex',    'v', base32, '0123456789abcdefghijklmnopqrstuv'},
  {'base32hexpad', 't', base32, '0123456789abcdefghijklmnopqrstuv='},
  {'base32z',      'h', base32, 'ybndrfg8ejkmcpqxot1uwisza345h769'},
  {'base58flickr', 'Z', baseX,  '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'},
  {'base58btc',    'z', baseX,  '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'},
  {'base64',       'm', base64, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'},
  {'base64pad',    'M', base64, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='},
  {'base64url',    'u', base64, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'},
  {'base64urlpad', 'U', base64, 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_='},
}

local bases = {}
local codes = {}
local names = {}
for i = 1, #table do
  local name, code, fn, alphabet = unpack(table[i])
  bases[name] = { fn, alphabet }
  bases[code] = bases[name]
  codes[name] = code
  codes[code] = code
  names[name] = name
  names[code] = name
end
p(bases)
local function encode(nameOrCode, raw)
  collectgarbage()
  local base = assert(bases[nameOrCode], "Unknown name or code")
  collectgarbage()
  if type(base[1]) == 'function' then 
    collectgarbage()
    base = base[1](base[2])
    collectgarbage()
    bases[nameOrCode] = base
    collectgarbage()
  end
  collectgarbage()
  local code = codes[nameOrCode]
  collectgarbage()
  return code .. base.encode(raw), names[code]
end

local function decode(encoded)
  collectgarbage()
  local code = encoded:sub(1, 1)
  collectgarbage()
  local base = assert(bases[code], "Unknown code in prefix")
  collectgarbage()
  return base.decode(encoded:sub(2)), names[code]
end

return {
  encode = encode,
  decode = decode
}