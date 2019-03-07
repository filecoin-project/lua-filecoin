return {
  name = "filecoin-project/lua-filecoin",
  version = "0.0.1",
  description = "Prototype of Filecoin in Lua",
  tags = { "filecoin", "p2p" },
  luvi = {
    inline = "#!/usr/local/bin/luvi --\n"
  },
  license = "MIT/Apache",
  author = { name = "Tim Caswell", email = "tim.caswell@protocol.ai" },
  homepage = "https://github.com/filecoin-project/lua-filecoin",
  dependencies = {
    "luvit/require",
    "luvit/pretty-print",
  },
  files = {
    "**.lua",
    "!test*"
  }
}

