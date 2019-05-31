
local function identity()
  local function passthrough(message) return message end
  return {
    encode = passthrough,
    decode = passthrough
  }
end

local table = {
  {'identity',         '\0', identity},
  {'base2',             '0', "base-2",  '01'},
  {'base8',             '7', "base-8",  '01234567'},
  {'base10',            '9', "base-x",  '0123456789'},
  {'base16',            'f', "base-16", '0123456789abcdef'},
  {'base16upper',       'F', "base-16", '0123456789ABCDEF'},
  {'base32',            'b', "base-32", 'abcdefghijklmnopqrstuvwxyz234567'},
  {'base32upper',       'B', "base-32", 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567'},
  {'base32pad',         'c', "base-32", 'abcdefghijklmnopqrstuvwxyz234567='},
  {'base32padupper',    'C', "base-32", 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567='},
  {'base32hex',         'v', "base-32", '0123456789abcdefghijklmnopqrstuv'},
  {'base32hexupper',    'V', "base-32", '0123456789ABCDEFGHIJKLMNOPQRSTUV'},
  {'base32hexpad',      't', "base-32", '0123456789abcdefghijklmnopqrstuv='},
  {'base32hexpadupper', 'T', "base-32", '0123456789ABCDEFGHIJKLMNOPQRSTUV='},
  {'base32z',           'h', "base-32", 'ybndrfg8ejkmcpqxot1uwisza345h769'},
  {'base58flickr',      'Z', "base-x",  '123456789abcdefghijkmnopqrstuvwxyzABCDEFGHJKLMNPQRSTUVWXYZ'},
  {'base58btc',         'z', "base-x",  '123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz'},
  {'base64',            'm', "base-64", 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'},
  {'base64pad',         'M', "base-64", 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/='},
  {'base64url',         'u', "base-64", 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_'},
  {'base64urlpad',      'U', "base-64", 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-_='},
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

local function getBase(nameOrCode)
  local base = assert(bases[nameOrCode], "Unknown name or code")
  if type(base[1]) == 'string' then
    base[1] = require(base[1])
  end
  if type(base[1]) == 'function' then
    base = base[1](base[2])
    bases[nameOrCode] = base
  end
  return base
end

local function encode(raw, nameOrCode)
  local base = getBase(nameOrCode)
  local code = codes[nameOrCode]
  return code .. base.encode(raw), names[code]
end

local function decode(encoded)
  local code = encoded:sub(1, 1)
  local base = getBase(code)
  return base.decode(encoded:sub(2)), names[code]
end

return {
  getBase = getBase,
  encode = encode,
  decode = decode
}