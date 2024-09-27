# Things To Do

1. "patch" the `main.c` to init a pass-core (instead of the standard core
   init). Our pass-core pulls in our parallel doc code to re-implement the
   open-file and save-file code to work with pass entries.

   To do this we need to expand the "plugins" directories to allow
   multiple plugins directories.

2. We need to implement an opt-entry and place this new function in the
   toolbar.

3. Add new tools to display different parts of a pass entry.

## xsel and xclip

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
