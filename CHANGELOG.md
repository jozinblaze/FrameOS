# Changelog

Newest first. Every entry is one commit and one git tag.

## 1.7.0 - Hunger and thirst
- Hunger and thirst, kept on the server (d.needs, 0 to 100). The server lowers them once a minute (Config.needs); food and drink items raise them (food = and drink = in data/items.lua)
- Nothing is drawn while you are fine. A small orange line (Hungry, Thirsty, Starving, Dehydrated) shows under the job text when one is low, and you get one notification as you cross the line. /needs shows the numbers
- Health regen follows your needs: normal speed when fed, slower when getting low, none when very low. At 0 you slowly lose health but never below a floor, so it cannot kill you
- Eating and drinking play an upper-body animation (you can still walk). Food or drink is refused, and not used up, if you are not hungry or thirsty
- New commands: /eat and /drink (use the item that fills the most), /needs, /setneeds (admin test command). /use also works for food and drink
- Waking up at the hospital lifts hunger and thirst to at least 50. Modules can now hook into that with FrameOS.onRespawn on the server
- tests/server_test.lua covers needs; tests/client_test.lua checks the regen and starving rules

## 1.6.2 - Safety sweep
- New players start unarmed: Config.loadout is empty. The old kit is now Config.testLoadout, used only by the /guns test command
- Shops, the garage and ped changes can no longer freeze: models load through FrameOS.loadModel with a 5 second limit (a car that would not load used to hang the shop menu with you frozen)
- A player file that fails to write is no longer marked saved; it stays queued and is retried, and the failure is printed
- A player file that parses but is not a table is treated as broken (copied to .broken) instead of crashing the load
- Request timers are cleared when a player leaves (server ids get reused); the hourly job cap is tracked per license so leaving and rejoining cannot reset it
- The client asks the server for its data again if the first hello is lost (up to 5 tries) and says so if it never arrives
- The log file is set aside at 400 KB instead of 2 MB, because the whole file is re-read on every write
- tests/server_test.lua: runs the real server files against a pretend FiveM (saving, bank, ATM limit, job cap, trunks)

## 1.6.1 - Storage fixes from testing
- Shift+Enter in storage now moves as many as fit instead of failing with 'bad request' on a big stack; the server limit per move is 1,000,000
- Glovebox prompt only shows when the car is nearly stopped (no distracting prompt while driving)
- Shorter help line in the storage menu so it no longer cuts off
- Removed the duplicate Config.testCommands line in config.lua

## 1.6.0 - Storage: bag weight, trunks, gloveboxes, stashes
- Storage: one container idea (a list of item -> count kept on the server) used for your bag, car trunks, car gloveboxes and safehouse stashes
- Weight limits (data/storage.lua): bag 30 kg, glovebox 5 kg, trunk by vehicle category, stash 100 kg; shops refuse when your bag is too heavy
- Trunk: stand at the back of a car you own and press E. Glovebox: sit in it and press G. Stash: at a safehouse circle press G
- Two-list menu (You / container): Left and Right switch, Up and Down choose, Enter moves one, Shift+Enter moves all
- Storage is kept by the car's plate in your save file, never filtered or cleared on load, and a car can't be sold until its trunk and glovebox are empty
- New requests storageOpen and storageMove (server/storage.lua) check ownership, place, weight and log every move; /inv shows weight

## 1.5.0 - Banking and ATMs
- Banking: 8 bank counters (blip, E to open) and ATMs found by their prop model anywhere on the map
- Deposit and withdraw with quick amounts, everything possible, or a typed amount
- ATM withdrawals are capped per day (Config.atmDailyLimit, default $5,000); banks have no cap; putting money in is never capped
- The account lives on the server (new 'bank' request): checks cash, balance, bank position and the daily limit, logs everything
- New data/banks.lua for banks, ATM models, limit and amounts; test command /setbank (admin)

## 1.4.1 - Data safety and pimp animations
- Import no longer throws data away: cars are kept even if the model is not in the Vehicles list, and the cash cap is a setting (Config.importCashMax, default 2,000,000)
- Config.importEnabled: turn the import OFF before sharing the server
- Daily backup of every player file in playerdata/backups/
- Admin /givecar <model> [price] to put a car in someone's garage (restore a lost car)
- Added the Ellie to data/vehicles.lua
- Pimp job: girls and customers now play scenario animations while waiting, riding to pickup, collecting and talking (lists in data/jobs.lua, swappable)

## 1.4.0 - Server foundation, stage 2: money and purchases
- Money, the bag, owned cars and job rank now live on the server (server/economy.lua); the client only shows what it is sent (FrameOS.data)
- Buying items and cars, selling a car, using an item, cash pickups, the hospital bill and job pay are all requests the server checks: shop and position, stock, price, cooldowns, payout limits, an hourly job cap
- One-time import of the cash, bag, cars and job rank saved on your own computer (capped, logged, only once)
- givecash, setcash and giveitem go through the server and need admin; Config.admins and /myid
- Cash changes show as +$ or -$ from one place
- Every purchase, payout and refusal is written to logs/frameos.log

## 1.3.0 - Server foundation, stage 1
- Server foundation, stage 1: server/core.lua with saved player data (one readable JSON file per player), a request system (FrameOS.onAsk / FrameOS.ask), rate limits, a log file and an admin check
- Data files (config, items, vehicles, shops, jobs) now load on both the server and the client
- Config.admins and /myid; the preset export checks FrameOS.isAdmin
- Test command /serverstatus shows what the server has saved for you
- Nothing is moved to the server yet: cash, items, cars and jobs still save on your computer until the next stages

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

