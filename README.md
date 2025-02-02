# Static Analysis for Textadept
This module integrates static analyzers with [Textadept](https://github.com/orbitalquark/textadept). Currently, the module integrates [`luacheck`](https://github.com/mpeterv/luacheck) with annotations and indicators (squiggle markers) for errors and warnings within the code editor. 

The module calls the static analyzer each time when a file is saved. You can integrate additional static analyzers with this module by following the `luacheck` example. 

The module takes the responsibility of displaying the errors and warnings within the editor itself; however, your submodule is expected to:
1. provide the shell command with all the options and arguments;
2. parse the output of the static analyzer; and 
3. sort the results into errors and warnings (see how all of this is done with the `luacheck` example).

## Usage
To load `textadept-analyzer`, add the following line in your `init.lua`:
```lua
local analyzer = require("textadept-analyzer")
```
Once you open a Lua file, the analyzer will begin to call `luacheck` as you edit and save the file.

## Compatibility
The module was updated and tested with Textadept 12.6. Thanks to Ian Nomar.