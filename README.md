## Building

This project is built using [lit](https://github.com/luvit/lit) which can be installed at the [luvit.io](http://luvit.io/install.html) website.

Basically lit (Luvit Inventors Toolkit) will collect dependencies defined in package.json as well as source files in this repo and bundle them into a single zipfile.  It will then prepend this with a shebang line with the path to luvi (currently hard-coded in package.lua) to form a single-file executible. Also the luvi binary itself can be prepended instead of a shebang line pointing to it (this is actually default behavior.)

So assuming you're on a unix system and your user can write to `/usr/local/bin`, the following will install `lit` and `luvi` as well as build `lua-filecoin`.

```sh
cd /usr/local/bin
# Download lit.zip and luvi from github releases and bootstrap lit.
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
# Sometimes update will get an even newer version than what get-lit points to.
lit update
# Download lua-filecoin from github and build.
lit make https://github.com/filecoin-project/lua-filecoin
```


