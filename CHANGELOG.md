# Changelog

Newest first. Every entry is one commit and one git tag.

## 1.2.2 - Criminal job spots are hidden
- Criminal jobs get no map icon at their clock-in spot (nobody can watch the map for crime); their girl and customer blips are local to your screen while you work

## 1.2.1 - Pimping job fixes
- Pimping peds are local-only (not networked), so players at the same pickup cannot get doubled or desynced peds
- A girl that spawns dead, vanishes, or dies while waiting is replaced quietly and your streak stays
- Rival gang difficulty settings in data/jobs.lua: rivalCount, rivalAccuracy, rivalAttackDistance (accuracy lowered to 25-40)

## 1.2.0 - Pimping job
- Pimping job (modules/jobs/pimp.lua), rewritten from scratch as a job-engine job: girls, customers, payday, problem customers, rival gangs
- All pimping settings, ranks, ped models, names and text live in data/jobs.lua under Jobs.pimp
- Paid per customer with a streak bonus; reputation rank sets how many girls work for you (2 to 5)
- Engine: jobs without every are not paid by the timer, FrameOS.jobRank, rep never below 0
- /setjobspot <job> places a clock-in spot where you stand, saved and included in /exportpresets
- FrameOS.message: text-message style notification with a sender

## 1.1.0 - Job system and the Courier job
- Job engine (modules/jobs.lua): clock in at a spot with E, one job at a time, payouts only while the job is active, idle clock-out, reputation and ranks, on-duty line under the cash counter
- data/jobs.lua: jobs as plain data (label, kind, spot, pay, interval, ranks)
- First job: Courier (drive and keep moving) at Legion Square
- FrameOS.jobPay is the one place job money is given out, ready for server-side pay later
- Commands: /clockout and /jobstats for players, /job <name> for testing

## 1.0.0 - Player and world review pass
- Help prompts draw for one frame only, so they vanish as soon as you leave range (the ghost motel prompt)
- Dying clears your wanted level
- Loading saved state waits for the ground (FrameOS.placePed) so you cannot fall through the map
- Saving keeps your last grounded spot instead of a mid-air one
- HUD refreshes street name and watch twice a second instead of every frame
- Game clock is saved and continues on relog (Config.saveClock)
- Weather cycle from a pool (Config.weatherCycle, weatherPool, weatherEvery)
- Resting at a safehouse saves your state
- Cash pickup comes back after 30 minutes (Config.pickupCashRespawn)

## 0.9.0 - Shops and vehicle ownership review pass
- Shops close when you die and only open while you are on foot
- /sellcar needs confirm on the end
- Owned cars save an id, a plate and two colors and come out with them (older saved cars are given some once)
- Rob's Liquor and Del Vecchio sell a liquor list, Don's a country-store list, 24/7 and LTD keep the full list
- Exotic dealership marked blocked by the MLO; notes added about the spawn and preview spots

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

