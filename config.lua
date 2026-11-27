-- config: the things you'll most likely want to change.
-- no code to read here, just settings.

Config = {}

-- world: the time you start at (24h clock, 18 = 6 PM) and the weather
Config.hour = 18
Config.minute = 30
Config.weather = 'EXTRASUNNY'   -- try CLEAR, CLOUDS, SMOG, FOGGY, RAIN, THUNDER
-- true = the time continues from where you left off when you log back in
-- (Config.hour and Config.minute above are only the very first start)
Config.saveClock = true
-- true = the weather changes on its own every few minutes, false = it stays on Config.weather.
-- the list below is the pool it picks from. a name listed twice is picked more often.
Config.weatherCycle = true
Config.weatherEvery = 600000    -- real milliseconds between changes (600000 = 10 minutes)
Config.weatherPool = {
    'EXTRASUNNY', 'EXTRASUNNY', 'EXTRASUNNY', 'CLEAR', 'CLEAR', 'CLEAR',
    'CLOUDS', 'CLOUDS', 'OVERCAST', 'RAIN', 'THUNDER', 'FOGGY',
}
-- how long one game minute lasts in real milliseconds.
-- 2000 is the game's normal speed, a bigger number is slower, 0 freezes the clock.
Config.msPerGameMinute = 2000

-- admins: the license ids that count as admins on the server (they can use the
-- commands that touch money and items). type /myid in game to get yours, then
-- paste it here, like { 'license:0123abcd...' }. you can also give the permission
-- frameos.admin in server.cfg instead.
Config.admins = {}

-- one switch for everything that is for testing or building, not for playing:
-- cheats (heal, god, givecash, car...), teleports, ped and clothes tools,
-- time and weather, IPL tools, and the placing tools (setshop, addpickup, exportpresets...).
-- set this to false for the live server. the player commands stay (inv, use, mycars, respawn, hud).
Config.testCommands = true

-- map icons for shops, safehouses, hospitals and your car. false turns them all off.
Config.showBlips = true

-- hud
Config.radarOnFoot = false      -- false = minimap only shows while you're in a vehicle
-- the time in the readout only shows while you wear a watch (prop slot 6).
-- set watchRequired to false to always show it.
Config.watchRequired = true
Config.watchSlot = 6
-- default HUD pieces to hide (the game's component ids):
-- 1 wanted stars, 2 weapon icon, 3 cash, 4 online cash, 5 online messages,
-- 6 vehicle name, 7 area name, 8 vehicle class, 9 street name,
-- 13 cash change, 17 saving icon, 18 online game stream popups
Config.hideHud = { 1, 2, 3, 4, 5, 6, 7, 8, 9, 13, 17, 18 }

-- where the street and time readout sits (0.0 to 1.0 across and down).
-- in a vehicle it moves to the right of the minimap and shows speed too.
Config.readoutFoot = { x = 0.015, y = 0.90 }
Config.readoutCar = { x = 0.19, y = 0.90 }
Config.useMph = true            -- false = km/h

-- what a brand new player spawns with. EMPTY on purpose: nobody starts armed.
-- weapons come from shops. (a saved state, see state.lua, brings back what you carried.)
-- put lines like these in if you ever want a starter kit:
--     { name = 'WEAPON_BAT', ammo = 1 },
--     { name = 'WEAPON_PISTOL', ammo = 250 },
Config.loadout = {}

-- the kit the /guns test command gives (test commands only, never given on spawn).
-- trunk = true marks a heavy weapon (used by modules/trunk.lua when Config.trunkWeapons is on).
Config.testLoadout = {
    { name = 'WEAPON_BAT',          ammo = 1 },
    { name = 'WEAPON_PISTOL',       ammo = 250 },
    { name = 'WEAPON_PUMPSHOTGUN',  ammo = 100, trunk = true },
    { name = 'WEAPON_MICROSMG',     ammo = 300, trunk = true },
    { name = 'WEAPON_CARBINERIFLE', ammo = 300, trunk = true },
}

-- weapon-wheel trunk is OFF for now. real vehicle storage comes with the inventory rework.
-- false = heavy weapons above are carried like any other weapon.
Config.trunkWeapons = false

Config.trunkRange = 3.0         -- how close to the trunk you need to be (meters)
Config.trunkLeaveRange = 8.0    -- walk farther than this and the weapons go back in

-- every weapon the game should remember (ped swaps and saving use this list).
-- add the names of any other weapons you use.
Config.allWeapons = {
    'WEAPON_BAT', 'WEAPON_KNIFE', 'WEAPON_CROWBAR', 'WEAPON_GOLFCLUB',
    'WEAPON_HAMMER', 'WEAPON_MACHETE', 'WEAPON_FLASHLIGHT',
    'WEAPON_SWITCHBLADE', 'WEAPON_NIGHTSTICK', 'WEAPON_HATCHET', 'WEAPON_WRENCH',
    'WEAPON_PISTOL', 'WEAPON_COMBATPISTOL', 'WEAPON_APPISTOL',
    'WEAPON_SNSPISTOL', 'WEAPON_VINTAGEPISTOL', 'GADGET_PARACHUTE',
    'WEAPON_STUNGUN', 'WEAPON_MICROSMG', 'WEAPON_SMG',
    'WEAPON_PUMPSHOTGUN', 'WEAPON_SAWNOFFSHOTGUN', 'WEAPON_ASSAULTSHOTGUN',
    'WEAPON_ASSAULTRIFLE', 'WEAPON_CARBINERIFLE', 'WEAPON_ADVANCEDRIFLE',
    'WEAPON_SNIPERRIFLE', 'WEAPON_HEAVYSNIPER',
    'WEAPON_GRENADE', 'WEAPON_MOLOTOV',
}

-- saving: how often your state (ped, health, weapons, position) is saved
Config.saveEvery = 15000        -- milliseconds

-- starter places for /spot (x, y, z). stand somewhere and use /setspot
-- to make your own. the z (height) of these may need adjusting.
Config.startSpots = {
    -- from published spawn point lists, so they should sit on solid ground
    spawn  = { x = 327.56, y = -205.08, z = 53.08 },   -- where you start with no saved state (the motel)
    legion = { x = 195.17, y = -933.77, z = 29.7 },
    police = { x = 428.23, y = -984.28, z = 29.76 },
    pdm    = { x = -45.67, y = -1098.34, z = 26.42 },   -- the car dealership
    motel  = { x = 327.56, y = -205.08, z = 53.08 },
    paleto = { x = 80.35,  y = 6424.12, z = 31.67 },
    -- my own estimates, the height may be off
    pier    = { x = -1850.0, y = -1230.0, z = 13.0 },
    airport = { x = -1037.0, y = -2737.0, z = 20.2 },
}

-- cash
Config.startCash = 500          -- what you begin with the very first time

-- pickups: floating icons around the map. kinds: health, armor, cash.
-- the first two sit on spawn points from published lists. the last two are
-- my own estimates, so the height may be off. use /addpickup for your own,
-- then /exportpresets to turn what you placed into presets.
Config.pickups = {
    { kind = 'armor',  x = 428.23,  y = -984.28,  z = 29.76 },   -- police station
    { kind = 'health', x = 80.35,   y = 6424.12,  z = 31.67 },   -- Paleto Bay
    { kind = 'cash',   x = 200.0,   y = -930.0,   z = 29.7 },    -- Legion Square
    { kind = 'health', x = -1846.0, y = -1226.0,  z = 13.0 },    -- the pier
}
Config.pickupCash = 250         -- what a cash pickup gives
Config.pickupRespawn = 60000    -- how long until a health or armor pickup comes back (milliseconds)
Config.pickupCashRespawn = 1800000   -- cash comes back much slower (30 minutes), or it is a money farm

-- safehouses: places to rest (press E). make more with /setsafehouse.
Config.safehouses = {
    motel = { x = 327.56, y = -205.08, z = 53.08 },
}

-- shops (item stores and car dealerships) live in data/shops.lua,
-- what they sell comes from data/items.lua and data/vehicles.lua.

-- jobs: the jobs themselves are in data/jobs.lua.
-- how long you can stand around (not working) before you are clocked out.
Config.jobIdleLimit = 300000    -- milliseconds, 300000 = 5 minutes

-- death: where you wake up and what it costs.
-- these are the spots as given, hospital interiors don't exist in the
-- base game so wherever you put them, check you wake up on solid ground.
Config.hospitals = {
    { name = 'Pillbox', x = 299.63,  y = -579.15,  z = 43.26, h = 0.0 },
    { name = 'Central', x = 337.39,  y = -1393.26, z = 32.51, h = 0.0 },
    { name = 'Paleto',  x = -245.25, y = 6328.88,  z = 32.43, h = 0.0 },
}
-- the first time you join, what you had saved on your own computer (cash, bag, cars,
-- job rank) is copied up to the server, once. the server cannot verify that copy, so
-- turn this OFF before you share the server with other people.
Config.importEnabled = true
Config.importCashMax = 2000000   -- the most cash that copy can bring
-- the most a player can earn from jobs in one hour. a safety net, not a design limit.
Config.jobHourlyCap = 30000

Config.hospitalBill = 250       -- most you pay (you never go below $0)

-- hunger and thirst (100 = full, 0 = empty). the server lowers them once a minute.
-- at these speeds you go from full to empty in about 2 hours (hunger) and 1.5 hours (thirst).
Config.needs = {
    hungerPerMinute = 0.8,
    thirstPerMinute = 1.1,
    warnAt = 25,         -- "you are getting hungry" and the small status line start here
    afterDeath = 50,     -- waking up at the hospital: lifted to at least this
    -- health regen speed (1.0 is the game's normal speed, 0 is none)
    regenFed = 1.0,      -- when both are above regenSlowAt
    regenSlowAt = 50,    -- at or below this, health comes back slower
    regenSlow = 0.5,
    regenStopAt = 25,    -- at or below this, health stops coming back by itself
    -- when one is at 0 you lose health, but never below the floor (so it can't kill you).
    -- health runs 100 (dead) to 200.
    damage = 2, damageEvery = 6000, floor = 110,
    useTime = 2500,      -- how long the eating and drinking animation runs (ms)
}
Config.respawnDelay = 4000      -- how long the death screen shows (milliseconds)
Config.deathText = 'WASTED'

-- IPLs: map pieces (interiors, props) the game loads on startup.
-- build = only load when the game build is at least this number.
-- example: { name = 'some_ipl_name', build = 2189 }
-- use /ipl <name> in game to test whether a name works. see modules/ipl.lua
Config.ipls = {}
Config.removeIpls = {}          -- names to unload (for IPLs that clash)
