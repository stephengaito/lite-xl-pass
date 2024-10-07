# Things To Do

1. **consider:** Wrap whole lua project in to one elf executable
   (including Lua libraries and *.so files).... Is this possible?

   see:
     - [pocomane/glua: Embed lua runtime and script in a single executable](https://github.com/pocomane/glua)
     - [(lua) squish: Summary](https://code.matthewwild.co.uk/squish)
     - [wxlua/wxLua/util/bin2c/bin2c.lua at master · pkulchenko/wxlua](https://github.com/pkulchenko/wxlua/blob/master/wxLua/util/bin2c/bin2c.lua)
     - [Luiz Henrique de Figueiredo: Libraries and tools for Lua](http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/#srlua)
       - http://webserver2.tecgraf.puc-rio.br/~lhf/ftp/lua/ar/srlua-102.tar.gz

   also:
     - [jirutka/luapak: Easily build a standalone executable for any Lua program](https://github.com/jirutka/luapak)
     - [PhysicsFS](https://icculus.org/physfs/)

## Resources and Ideas

### xsel and xclip

The command
```
echo "This is a test" | xclip -l 1 -selection clipboard
```
will clear the clipboard after *1* paste....


The command
```
echo "This is a test" | xsel -t 40000 -b
```
will clear the clipboard after 40000 milliseconds (40 seconds)

The command
```
xsel -c -b
```
will clear the clipboard.

The lite-xl uses SDL_{Get|Set}ClipboardText to get or set the clipboard
contents. There is no direct way to have the clipboard cleared after a set
time or number of pastes. I *think* SDL_ClearClipboardText will clear the
clipboard (but alas reading the code I am not sure of this fact).
