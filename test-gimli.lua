local ffi = require 'ffi'
local gimli = require 'gimli-permutation'

local function dump(state)
  print(string.format('%08x %08x %08x %08x %08x %08x', state[0], state[1], state[2], state[3], state[4], state[5]))
  print(string.format('%08x %08x %08x %08x %08x %08x', state[6], state[7], state[8], state[9], state[10], state[11]))
  end

local state = ffi.new 'uint32_t[3*4]'
dump(state)
gimli(state)
print()
dump(state)
