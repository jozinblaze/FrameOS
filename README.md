# FrameOS

A from-scratch FiveM framework that gives GTA V a Vice City / GTA VI style feel.
No QBCore, Qbox or ESX. Everything is one resource with small modules.

## Layout
- `config.lua` - every setting you change
- `data/` - items, vehicles and shops (the lists)
- `core.lua` - shared helpers: notify, save/load, blips, commands, spawn hook
- `modules/` - one file per feature, loaded in the order of `fxmanifest.lua`
- `server.lua` - tiny, only saves exported presets

## Rules of the house
- `Config.testCommands = false` removes every cheat, teleport and build tool
- saving is client-side for now (KVP); server-side saving comes before sharing
- the weapon-wheel trunk is parked (`Config.trunkWeapons = false`)

## History
Versions 0.1.0 to 0.6.0 were rebuilt from the build log, so they are close to what
existed at the time but not guaranteed to run. 0.7.0 is the tested current version.
See `CHANGELOG.md`.
