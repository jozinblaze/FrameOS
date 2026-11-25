# Changelog

Newest first. Every entry is one commit and one git tag.

 ## 0.8.0 - Money and items review pass
 - Cash is whole dollars only; zero and negative amounts are ignored
 - /inv skips items that no longer exist; old saved names are migrated
 - Items renamed to GTA ones (Burger Shot, Cluckin Bell, eCola, Sprunk, Pisswasser); Fitbit removed
 - Every item has a weight field for the coming storage rework
 - Buying a weapon you already carry is blocked
 - Hospital bill lowered to $250

## 0.7.0 - Test switch, vehicle-aware blip, trunk parked
- Config.testCommands now covers every cheat, teleport, debug and build command (FrameOS.testCommand)
- Car blip hides while you are inside, named after the model, icon by vehicle type
- Weapon-wheel trunk parked behind Config.trunkWeapons = false
- Tested in game: shops, data files, bag, respawn, watch clock, blips

## 0.6.0 - Typed shops, shop presets, respawn height fix
- Two shop types: items and vehicles, with stock lists
- 36 preset stores from the old qb shop config plus two dealerships
- Respawn ground check fixed (no more rooftop spawns)
- Blips for shops, safehouses, hospitals and your car
- Clock that only shows with a watch, time that moves
- Trunk reworked (third attempt)

## 0.5.0 - Item and vehicle data files, bag
- data/items.lua, data/vehicles.lua, data/shops.lua first pass
- Inventory bag with /inv and /use
- Presets folder and respawn tweaks

## 0.4.0 - Owned cars, showroom shop, death and respawn
- Owned vehicles (mycars, mycar, sellcar)
- Showroom shop you place with /setshop
- Death screen and hospital respawn
- Server-side export of presets

## 0.3.0 - Trunk weapons, IPL loader, saved state
- First weapon-wheel trunk
- IPL loader with removal list
- Saved state: ped, health, armor, weapons and position survive a relog

## 0.2.0 - Cash, pickups, safehouses
- Cash counter and money formatting
- Health, armor and cash pickups you can place
- Safehouses with /home
- HUD: minimap only in vehicles, bars hidden

## 0.1.0 - Core, world, HUD, outfits, spots, garage
- FrameOS core: notifications, saving, command list, spawn hook
- World: clock and weather, HUD readout, outfits and ped swap, saved spots
- Garage-lite car spawning, basic essentials (heal, armor, guns)

