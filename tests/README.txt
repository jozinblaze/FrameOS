tests/server_test.lua runs the real server files (core, economy, storage) against a pretend
FiveM and checks saving, banking, the ATM limit, the hourly job cap and trunks.
Run it from the frameos folder with any Lua 5.3:   lua tests/server_test.lua
It is not loaded by the game (it is not in fxmanifest.lua), it is only for checking changes.
