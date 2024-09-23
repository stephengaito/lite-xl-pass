# Things To Do

1. "patch" the `main.c` to init a pass-core (instead of the standard core
   init). Our pass-core pulls in our parallel doc code to re-implement the
   open-file and save-file code to work with pass entries.

   To do this we need to expand the "plugins" directories to allow
   multiple plugins directories.

2. We need to implement an opt-entry and place this new function in the
   toolbar.

3. Add new tools to display different parts of a pass entry.
