## Building

This project is built using [lit](https://github.com/luvit/lit) which can be installed at the [luvit.io](http://luvit.io/install.html) website.

Basically lit (Luvit Inventors Toolkit) will collect dependencies defined in package.json as well as source files in this repo and bundle them into a single zipfile.  It will then prepend this with a shebang line with the path to luvi (currently hard-coded in package.lua) to form a single-file executible. Also the luvi binary itself can be prepended instead of a shebang line pointing to it (this is actually default behavior.)

So assuming you're on a unix system and your user can write to `/usr/local/bin`, the following will install `lit` and `luvi` as well as build `lua-filecoin`.

```sh
cd /usr/local/bin
# Download lit.zip and luvi from github releases and bootstrap lit.
curl -L https://github.com/luvit/lit/raw/master/get-lit.sh | sh
# Download lua-filecoin from github and build.
lit make https://github.com/filecoin-project/lua-filecoin/archive/master.zip
```

You should now have `lua-filecoin` in your path if all went well!

It is a self executing zip file.

```sh
tim@t580:~$ ls -lh $(which lua-filecoin)
-rwxr-xr-x 1 tim tim 8.2K Mar  5 20:35 /usr/local/bin/lua-filecoin
tim@t580:~$ lua-filecoin
Hello Filecoin
tim@t580:~$ unzip -l $(which lua-filecoin)
Archive:  /usr/local/bin/lua-filecoin
warning [/usr/local/bin/lua-filecoin]:  25 extra bytes at beginning or within zipfile
  (attempting to process anyway)
  Length      Date    Time    Name
---------  ---------- -----   ----
        0  1980-00-00 00:00   deps/
     6680  1980-00-00 00:00   deps/pretty-print.lua
     7231  1980-00-00 00:00   deps/require.lua
       24  1980-00-00 00:00   main.lua
      462  1980-00-00 00:00   package.lua
---------                     -------
    14397                     5 files
```