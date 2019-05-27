local p = require'pretty-print'.prettyPrint
local Multibase = require 'multibase'

local messages = {
  "Decentralize everything!!",
  {
    "0010001000110010101100011011001010110111001110100011100100110000101101100011010010111101001100101001" ..
      "00000011001010111011001100101011100100111100101110100011010000110100101101110011001110010000100100001",
    "72106254331267164344605543227514510062566312711713506415133463441102",
    "9429328951066508984658627669258025763026247056774804621697313",
    "f446563656e7472616c697a652065766572797468696e672121",
    "F446563656E7472616C697A652065766572797468696E672121",
    "birswgzloorzgc3djpjssazlwmvzhs5dinfxgoijb",
    "BIRSWGZLOORZGC3DJPJSSAZLWMVZHS5DINFXGOIJB",
    "v8him6pbeehp62r39f9ii0pbmclp7it38d5n6e891",
    "V8HIM6PBEEHP62R39F9II0PBMCLP7IT38D5N6E891",
    "cirswgzloorzgc3djpjssazlwmvzhs5dinfxgoijb",
    "CIRSWGZLOORZGC3DJPJSSAZLWMVZHS5DINFXGOIJB",
    "t8him6pbeehp62r39f9ii0pbmclp7it38d5n6e891",
    "T8HIM6PBEEHP62R39F9II0PBMCLP7IT38D5N6E891",
    "het1sg3mqqt3gn5djxj11y3msci3817depfzgqejb",
    "Ztwe7gVTeK8wswS1gf8hrgAua9fcw9reboD",
    "zUXE7GvtEk8XTXs1GF8HSGbVA9FCX9SEBPe",
    "mRGVjZW50cmFsaXplIGV2ZXJ5dGhpbmchIQ",
    "MRGVjZW50cmFsaXplIGV2ZXJ5dGhpbmchIQ==",
    "uRGVjZW50cmFsaXplIGV2ZXJ5dGhpbmchIQ",
    "URGVjZW50cmFsaXplIGV2ZXJ5dGhpbmchIQ==",
  },
  "yes mani !",
  {
    "001111001011001010111001100100000011011010110000101101110011010010010000000100001",
    "7362625631006654133464440102",
    "9573277761329450583662625",
    "f796573206d616e692021",
    "F796573206D616E692021",
    "bpfsxgidnmfxgsibb",
    "BPFSXGIDNMFXGSIBB",
    "vf5in683dc5n6i811",
    "VF5IN683DC5N6I811",
    "cpfsxgidnmfxgsibb",
    "CPFSXGIDNMFXGSIBB",
    "tf5in683dc5n6i811",
    "TF5IN683DC5N6I811",
    "hxf1zgedpcfzg1ebb",
    "Z7Pznk19XTTzBtx",
    "z7paNL19xttacUY",
    "meWVzIG1hbmkgIQ",
    "MeWVzIG1hbmkgIQ==",
    "ueWVzIG1hbmkgIQ",
    "UeWVzIG1hbmkgIQ==",
  },
  "hello world",
  {
    "00110100001100101011011000110110001101111001000000111011101101111011100100110110001100100",
    "7320625543306744035667562330620",
    "9126207244316550804821666916",
    "f68656c6c6f20776f726c64",
    "F68656C6C6F20776F726C64",
    "bnbswy3dpeb3w64tmmq",
    "BNBSWY3DPEB3W64TMMQ",
    "vd1imor3f41rmusjccg",
    "VD1IMOR3F41RMUSJCCG",
    "cnbswy3dpeb3w64tmmq======",
    "CNBSWY3DPEB3W64TMMQ======",
    "td1imor3f41rmusjccg======",
    "TD1IMOR3F41RMUSJCCG======",
    "hpb1sa5dxrb5s6hucco",
    "ZrTu1dk6cWsRYjYu",
    "zStV1DL6CwTryKyV",
    "maGVsbG8gd29ybGQ",
    "MaGVsbG8gd29ybGQ=",
    "uaGVsbG8gd29ybGQ",
    "UaGVsbG8gd29ybGQ=",
  },
  "\x00yes mani !",
  {
    "00000000001111001011001010111001100100000011011010110000101101110011010010010000000100001",
    "7000745453462015530267151100204",
    "90573277761329450583662625",
    "f00796573206d616e692021",
    "F00796573206D616E692021",
    "bab4wk4zanvqw42jaee",
    "BAB4WK4ZANVQW42JAEE",
    "v01smasp0dlgmsq9044",
    "V01SMASP0DLGMSQ9044",
    "cab4wk4zanvqw42jaee======",
    "CAB4WK4ZANVQW42JAEE======",
    "t01smasp0dlgmsq9044======",
    "T01SMASP0DLGMSQ9044======",
    "hybhskh3ypiosh4jyrr",
    "Z17Pznk19XTTzBtx",
    "z17paNL19xttacUY",
    "mAHllcyBtYW5pICE",
    "MAHllcyBtYW5pICE=",
    "uAHllcyBtYW5pICE",
    "UAHllcyBtYW5pICE=",
  },
  "\x00\x00yes mani !",
  {
    "0000000000000000001111001011001010111001100100000011011010110000101101110011010010010000000100001",
    "700000171312714403326055632220041",
    "900573277761329450583662625",
    "f0000796573206d616e692021",
    "F0000796573206D616E692021",
    "baaahszltebwwc3tjeaqq",
    "BAAAHSZLTEBWWC3TJEAQQ",
    "v0007ipbj41mm2rj940gg",
    "V0007IPBJ41MM2RJ940GG",
    "caaahszltebwwc3tjeaqq====",
    "CAAAHSZLTEBWWC3TJEAQQ====",
    "t0007ipbj41mm2rj940gg====",
    "T0007IPBJ41MM2RJ940GG====",
    "hyyy813murbssn5ujryoo",
    "Z117Pznk19XTTzBtx",
    "z117paNL19xttacUY",
    "mAAB5ZXMgbWFuaSAh",
    "MAAB5ZXMgbWFuaSAh",
    "uAAB5ZXMgbWFuaSAh",
    "UAAB5ZXMgbWFuaSAh",
  },
}

collectgarbage()
local message
for _, list in ipairs(messages) do
  collectgarbage()
  if type(list) == 'string' then
    message = list
    print("\nMessage:")
    p(message)
    print()
  else
    collectgarbage()
    for _, input in ipairs(list) do
      collectgarbage()
      local code = input:sub(1,1)
      collectgarbage()
      print("Encoding " .. code)
      collectgarbage()
      local encoded, name = Multibase.encode(message, code)
      collectgarbage()
      p(name, encoded)
      collectgarbage()
      if encoded ~= input then
        print("Expected: " .. input)
        print("But got:  " .. encoded)
        assert(encoded == input)
      end
      collectgarbage()
      print("Decoding " .. code)
      local decoded, name2 = Multibase.decode(encoded)
      p(name2, decoded)
      collectgarbage()
      if decoded ~= message then
        print("Expected: " .. message)
        print("But got:  " .. decoded)
        assert(decoded == message)
      end
      collectgarbage()
      assert(name == name2)
      collectgarbage()
    end
    collectgarbage()
  end
end
collectgarbage()
