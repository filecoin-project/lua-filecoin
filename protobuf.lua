local sub = string.sub
local Varint = require 'varint'

local Protobuf = {}

local function encodeValue(fieldNumber, val)
  if not val then
    return ''
  end
  local typ = type(val)
  if typ == 'string' then
    local key = 2 | fieldNumber << 3
    local len = #val
    return table.concat {
      Varint.encode(key),
      Varint.encode(len),
      val
    }
  elseif typ == 'number' then
    local key = fieldNumber << 3
    return table.concat {
      Varint.encode(key),
      Varint.encode(val)
    }
  end
end

local function decodeValue(data, index)
  local key, len
  key, index = Varint.decode(data, index)
  local fieldNumber = key >> 3
  local typ = key & 7
  local val
  if typ == 0 then
    val, index = Varint.decode(data, index)
  elseif typ == 1 then
    error('TODO: implement 64bit decoder')
  elseif typ == 2 then
    len, index = Varint.decode(data, index)
    val = sub(data, index, index + len - 1)
    index = index + len
  elseif typ == 5 then
    error('TODO: implement 32bit decoder')
  else
    error('Unexpected protobuf type: ' .. typ)
  end
  return fieldNumber, val, index
end

-- For now assume all values are strings
function Protobuf.encodeTable(schema, val)
  local parts = {}
  for i = 1, #schema do
    parts[i] = encodeValue(i, val[schema[i]])
  end
  return table.concat(parts)
end

function Protobuf.decodeTable(schema, data)
  local val = {}
  local index = 1
  local len = #data
  while index <= len do
    local fieldNumber, str
    fieldNumber, str, index = decodeValue(data, index)
    val[schema[fieldNumber] or fieldNumber] = str
  end
  return val
end

return Protobuf
