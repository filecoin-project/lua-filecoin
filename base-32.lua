local u8Array = require 'u8-array'

return function (alphabet)
  local function encode()
    error "TODO: implement base32.encode"
  end
  local function decode()
    error "TODO: implement base32.decode"
  end
  return {
    encode = encode,
    decode = decode,
  }
end