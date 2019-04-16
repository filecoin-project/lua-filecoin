local Varint = require 'varint'

local Multiselect = {}

function Multiselect.negotiate(stream, protocol)
  protocol = protocol .. '\n'
  Varint.writeFrame(stream, '/multistream/1.0.0\n')
  Varint.writeFrame(stream, protocol)
  local first = Varint.readFrame(stream)
  assert(first == '/multistream/1.0.0\n')
  local second = Varint.readFrame(stream)
  assert(second == protocol)
end

return Multiselect
