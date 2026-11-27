tests/server_test.lua runs the real server files (core, economy, storage) against a pretend
FiveM and checks saving, banking, the ATM limit, the hourly job cap and trunks.
Run it from the frameos folder with any Lua 5.3:   lua tests/server_test.lua
It is not loaded by the game (it is not in fxmanifest.lua), it is only for checking changes.

tests/client_test.lua loads modules/needs.lua with a pretend game and checks the health regen
and starving rules. Run it the same way:   lua tests/client_test.lua

tests/corner_test.lua checks the stacking of the top right text lines (FrameOS.corner in core.lua).
