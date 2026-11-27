# FrameOS modules

What every file owns, what it offers to the others, and what it needs. Keep this current when a
module is added. The point: a module only uses another module through the functions listed here,
never by reaching into its variables. That is what makes it easy to change a module later, or
to split one into its own resource.

## Rules for a new module
1. One file in `modules/` (client) and, if it needs the server, one in `server/`. Add them to `fxmanifest.lua`.
2. Its numbers go in `config.lua`, its lists in `data/`.
3. The server decides, the client shows. Anything that moves money, items or cars is an `onAsk` on the server that re-checks everything.
4. Nothing runs every frame unless something is happening. Sleep (`Wait(250)` or more) when nothing is near. Text in the top right goes through `FrameOS.corner`.
5. Saved data goes through `FrameOS.store` (server) or `FrameOS.save` / `FrameOS.load` (client, local only).
6. Add a line to this file.

## Server

| File | Owns | Offers | Needs |
|---|---|---|---|
| `server/core.lua` | player files in memory, saving, the ask system, rate limits, the log, admin check | `FrameOS.getPlayer`, `markDirty`, `idOf`, `eachPlayer`, `onAsk`, `onRespawn`, `log`, `isAdmin` | `store` |
| `server/store.lua` | how data files are read and written | `FrameOS.store.path / read / write / copy / setAside` | nothing |
| `server/needs.lua` | hunger and thirst (`d.needs`) | `FrameOS.needsFull`, `needsEat`, `needsTick`; refills on respawn | `core` |
| `server/economy.lua` | cash, bank, the bag (`d.bag`), owned cars (`d.owned`), shop buying, item use, job pay, pickups, import, admin test requests | `FrameOS.addCash`, `takeCash`, `weightOf`, `push`; asks `buyItem buyVehicle sellVehicle useItem pickupCash hospitalBill jobPay jobRep bank import admin` | `core`, `needs` (for food and drink) |
| `server/storage.lua` | trunks, gloveboxes and stashes (`d.storage`) | asks `storageOpen`, `storageMove` | `core`, `economy` (`weightOf`) |
| `server.lua` | saving `/exportpresets` text | nothing | `core` (`isAdmin`) |

## Client

| File | Owns | Offers | Needs |
|---|---|---|---|
| `core.lua` | shared helpers | `notify message save load forget drawText corner help groundZ loadModel placePed addBlip addEntityBlip removeBlips snapshot restore command testCommand onSpawn addExport` | nothing |
| `modules/link.lua` | talking to the server, the copy of your data | `FrameOS.ask`, `request`, `FrameOS.data` | `core` |
| `modules/world.lua`, `ipl.lua` | time, weather, interiors | test commands | `core` |
| `modules/hud.lua` | hiding the default HUD, radar rule, street/time/speed readout | `/hud`, `/radar` | `core` |
| `modules/cash.lua` | the money counter | `FrameOS.getCash`, `formatMoney` | `link`, `core` (`corner`) |
| `modules/outfit.lua` | ped and clothing changes | `FrameOS.wearOutfit`, `readOutfit` | `core` (`loadModel`, `snapshot`) |
| `modules/spots.lua`, `garage.lua`, `pickups.lua`, `safehouses.lua`, `vehicles.lua` | saved spots, spawning cars, cash/health pickups, safehouse resting, your cars | `FrameOS.spawnVehicle` and test commands | `core`, `link` |
| `modules/bank.lua` | bank counters and ATMs menu | the E prompt | `link`, `cash` |
| `modules/inventory.lua` | the bag on screen, using items | `FrameOS.useItem`, `applyItem`, `canGive`, `/inv`, `/use` | `link` |
| `modules/storage.lua` | the trunk, glovebox and stash menu | `FrameOS.openStorage` | `link`, `inventory` |
| `modules/needs.lua` | hunger and thirst effects, the status line, `/eat`, `/drink`, `/needs` | `FrameOS.playUseAnimation` | `link`, `inventory` (`useItem`), `core` (`corner`) |
| `modules/jobs.lua` and `modules/jobs/*.lua` | the job engine and one file per job | `FrameOS.registerJob`, `currentJob`, `jobRank`, `jobPay` | `link`, `cash`, `core` (`corner`) |
| `modules/shop.lua` | item stores and car showrooms | the E prompt | `link`, `inventory`, `garage` |
| `modules/death.lua` | the death screen and respawn | `/respawn` | `link` |
| `modules/basics.lua`, `trunk.lua` | test commands; the old weapon-wheel trunk (switched off) | | `core` |
| `modules/state.lua` | saving and restoring ped, health, weapons, position (local, on your computer) | `FrameOS.saveState` | everything above (loads last) |

## Known tangles (honest list, for when something is split off)
- The bag, the shop, storage and item use all share `d.bag` and the weight rule (`weightOf`). They would move out together or not at all.
- `state.lua` still saves position, outfit and health on your own computer. It moves to the server with the character creator.
- `modules/trunk.lua` is the old weapon-wheel trunk and does nothing while `Config.trunkWeapons = false`. It can be deleted when the new weapon design is settled.
- Job pay amounts come from the client and are only range-checked on the server. A server-side on-duty state is needed to close that fully.
