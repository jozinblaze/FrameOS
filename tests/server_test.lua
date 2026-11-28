-- runs the REAL server files (server/core.lua, economy.lua, storage.lua) against a fake FiveM.
-- from the frameos folder:   lua tests/server_test.lua      (any Lua 5.3 works)
local fails = 0
local say = print
local function check(cond, msg)
    if cond then say('ok   ' .. msg) else say('FAIL ' .. msg); fails = fails + 1 end
end

-- ---------------------------------------------------------- fake FiveM
local files, handlers, events = {}, {}, {}
local saveWorks = true
local now = 0
local pos = { x = 0, y = 0, z = 0 }
local ids = { [1] = 'license:aaa', [2] = 'license:bbb', [3] = 'license:aaa' }

local function vec(x, y, z)
    return setmetatable({ x = x, y = y, z = z }, {
        __sub = function(a, b) return vec(a.x - b.x, a.y - b.y, a.z - b.z) end,
        __len = function(a) return math.sqrt(a.x ^ 2 + a.y ^ 2 + a.z ^ 2) end,
    })
end
vector3 = vec

-- tiny JSON that round-trips tables (good enough to test saving and loading)
local function ser(v)
    local t = type(v)
    if t == 'table' then
        local out = {}
        for k, x in pairs(v) do out[#out + 1] = string.format('[%q]=%s', tostring(k), ser(x)) end
        return '{' .. table.concat(out, ',') .. '}'
    elseif t == 'string' then return string.format('%q', v) end
    return tostring(v)
end
json = {
    encode = function(v) return 'T' .. ser(v) end,
    decode = function(s)
        if s:sub(1, 1) ~= 'T' then
            if s == '5' then return 5 end
            return nil
        end
        local env = {}
        local fn = load('return ' .. s:sub(2):gsub('%[%"([^"]-)%"%]=', function(k) return '["' .. k .. '"]=' end), 'j', 't', env)
        local data = fn()
        -- keys were saved as strings; turn numeric ones back into numbers
        local function fix(t)
            local r = {}
            for k, v in pairs(t) do
                if type(v) == 'table' then v = fix(v) end
                r[tonumber(k) or k] = v
            end
            return r
        end
        return fix(data)
    end,
}

function GetCurrentResourceName() return 'frameos' end
function LoadResourceFile(_, p) return files[p] end
function SaveResourceFile(_, p, c) if saveWorks or p:find('backups') or p:find('broken') then files[p] = c; return true end return false end
function GetGameTimer() return now end
function CreateThread() end
function Wait() end
function RegisterNetEvent(name, fn) handlers[name] = fn end
function AddEventHandler(name, fn) handlers[name] = handlers[name] or {}; if type(handlers[name]) == 'function' then handlers[name] = { handlers[name] } end table.insert(handlers[name], fn) end
function TriggerClientEvent(name, src, ...) events[#events + 1] = { name = name, src = src } end
function GetPlayerName(s) return 'P' .. s end
function GetPlayerIdentifierByType(s) return ids[s] end
function GetPlayerIdentifiers(s) return { ids[s] } end
function IsPlayerAceAllowed() return false end
function GetPlayerPed() return 1 end
function GetEntityCoords() return vec(pos.x, pos.y, pos.z) end
function print() end
os.date = os.date

local function fire(name, src, ...)
    local h = handlers[name]
    if type(h) == 'function' then _G.source = src; h(...) else for _, f in ipairs(h or {}) do _G.source = src; f(...) end end
end

-- the real config and data
local function run(f) local fn, e = loadfile(f); if not fn then error(e) end; return fn() end
Config = {}
run('config.lua')
for _, f in ipairs({ 'data/items.lua', 'data/vehicles.lua', 'data/shops.lua', 'data/jobs.lua', 'data/banks.lua', 'data/storage.lua', 'data/character.lua', 'data/clothes.lua' }) do run(f) end
files['local.lua'] = "Config.admins = { 'license:bbb', 'license:ccc' }\nConfig.somethingElse = 5\nos.exit(1)\n"   -- the last line must not be able to run
Config.testCommands = true

run('server/core.lua'); run('server/store.lua'); run('server/needs.lua'); run('server/character.lua'); run('server/clothes.lua'); run('server/economy.lua'); run('server/storage.lua')
local ask = function(src, name, ...)
    -- go through the real frameos:ask event and catch the answer
    local got
    local old = TriggerClientEvent
    TriggerClientEvent = function(n, s, id, ok, result) if n == 'frameos:answer' then got = { ok = ok, result = result } end end
    now = now + 8100   -- just past the longest rate limit (8 s), so requests are not "too fast"
    _G.source = src
    handlers['frameos:ask'](1, name, ...)
    TriggerClientEvent = old
    return got
end

-- ---------------------------------------------------------- tests
fire('frameos:join', 1)
local d = FrameOS.getPlayer(1)
check(d and d.cash == (Config.startCash or 0), 'a new player loads with the starting cash')
check(Config.loadout and #Config.loadout == 0, 'new players start with no spawn weapons')

-- saving: a failed write must not count as saved
d.cash = 777; FrameOS.markDirty(1)
saveWorks = false
fire('onResourceStop', 1, 'frameos')     -- tries to save everyone, the write fails
check(files['playerdata/license_aaa.json'] == nil, 'a failed write leaves no file')
saveWorks = true
fire('onResourceStop', 1, 'frameos')     -- the record stayed dirty, so the next save writes it
check(files['playerdata/license_aaa.json'] and json.decode(files['playerdata/license_aaa.json']).cash == 777,
    'after a failed write the data is still saved on the next try')
fire('playerDropped', 1)

-- unreadable file is kept, not overwritten
files['playerdata/license_bbb.json'] = 'garbage{{'
fire('frameos:join', 2)
local broken = false
for name in pairs(files) do if name:find('license_bbb.json.broken') then broken = true end end
check(broken, 'an unreadable player file is copied to .broken before starting fresh')
-- a file that parses but is not a table
fire('playerDropped', 2)
files['playerdata/license_bbb.json'] = '5'
fire('frameos:join', 2)
check(type(FrameOS.getPlayer(2)) == 'table', 'a file that is not a table does not crash the load')
check(FrameOS.getPlayer(2).cash == (Config.startCash or 0), '... and starts fresh')

-- bank
pos = { x = Config.banks[1].x, y = Config.banks[1].y, z = Config.banks[1].z }
d = FrameOS.getPlayer(2); d.cash = 1000; d.bank = 0
local r = ask(2, 'bank', 'deposit', 400, 'bank')
check(r.ok and r.result.ok and d.cash == 600 and d.bank == 400, 'deposit at a bank moves money')
r = ask(2, 'bank', 'deposit', 999999, 'bank')
check(r.result.ok == false and d.cash == 600, 'cannot deposit more than you carry')
pos = { x = 9999, y = 9999, z = 0 }
r = ask(2, 'bank', 'deposit', 100, 'bank')
check(r.result.ok == false, 'a bank deposit away from a bank is refused')
d.bank = 20000
r = ask(2, 'bank', 'withdraw', Config.atmDailyLimit + 1, 'atm')
check(r.result.ok == false, 'ATM refuses above the daily limit')
r = ask(2, 'bank', 'withdraw', Config.atmDailyLimit, 'atm')
check(r.result.ok == true, 'ATM gives up to the daily limit')
r = ask(2, 'bank', 'withdraw', 1, 'atm')
check(r.result.ok == false, 'ATM limit is used up')
r = ask(2, 'bank', 'withdraw', -5, 'atm')
check(r.result.ok == false, 'negative amounts are refused')

-- job cap is per license, not per server id
local names = {}
for id in pairs(Jobs) do names[#names + 1] = id end
table.sort(names, function(a, b) return Jobs[a].pay.max > Jobs[b].pay.max end)   -- the best paying job reaches the cap fastest
local jobId = names[1]
local job = Jobs[jobId]
local pay = job.pay.max
d.jobrep = d.jobrep or {}
local total, tries = 0, 0
while tries < 400 do   -- 400 requests at 8.1 s is still inside one hour
    r = ask(2, 'jobPay', jobId, pay, 0)
    if not (r.result and r.result.ok) then break end
    total = total + pay; tries = tries + 1
end
check(total <= Config.jobHourlyCap and total > Config.jobHourlyCap - pay * 2, 'job pay stops right at the hourly cap (' .. total .. ')')
fire('playerDropped', 2)
ids[2] = 'license:bbb'
fire('frameos:join', 2)
r = ask(2, 'jobPay', jobId, pay, 0)
check(r.result.ok == false, 'leaving and rejoining does not reset the hourly job cap')

-- storage: trunk and sellVehicle
d = FrameOS.getPlayer(2)
d.owned = { { id = 1, model = 'futo', name = 'Futo', price = 1000, plate = 'FRTEST1' } }
d.bag = { burger = 3 }
r = ask(2, 'storageMove', 'trunk', 'FRTEST1', 'in', 'burger', 2)
check(r.result and r.result.ok and d.bag.burger == 1 and d.storage['trunk:FRTEST1'].burger == 2, 'moving into a trunk works')
r = ask(2, 'storageMove', 'trunk', 'FRTEST1', 'in', 'burger', 5)
check(r.result.ok == false, 'cannot put in more than you have')
r = ask(2, 'storageMove', 'trunk', 'NOTMINE', 'in', 'burger', 1)
check(r.result.ok == false, 'cannot use a trunk you do not own')
r = ask(2, 'sellVehicle', 1)
check(r.result.ok == false, 'cannot sell a car with things in the trunk')
ask(2, 'storageMove', 'trunk', 'FRTEST1', 'out', 'burger', 2)
r = ask(2, 'sellVehicle', 1)
check(r.result.ok == true, 'an emptied car can be sold')

-- storage depends on the vehicle
d.owned = { { id = 2, model = 'faggio', name = 'Faggio', price = 4000, plate = 'BIKE1' }, { id = 3, model = 'futo', name = 'Futo', price = 1000, plate = 'CAR1' } }
d.bag = { burger = 2 }
r = ask(2, 'storageMove', 'trunk', 'BIKE1', 'in', 'burger', 1)
check(r.result.ok == false and r.result.why == 'This vehicle has no trunk', 'a bike has no trunk')
r = ask(2, 'storageMove', 'glove', 'BIKE1', 'in', 'burger', 1)
check(r.result.ok == false and r.result.why == 'This vehicle has no glovebox', 'a bike has no glovebox')
r = ask(2, 'storageMove', 'glove', 'CAR1', 'in', 'burger', 1)
check(r.result.ok, 'a car has a glovebox')
check(Config.trunkCapacity('rumpo') ~= nil and Config.trunkWeights.Commercial > Config.trunkWeights.Sedans, 'work vehicle categories carry more than a sedan')
Config.trunkByModel.futo = 500
check(Config.trunkCapacity('futo') == 500, 'a model override beats its category')
Config.trunkByModel.futo = nil
Config.gloveboxByModel.futo = 0
check(Config.gloveboxCapacity('futo') == 0, 'a glovebox override of 0 removes it')
Config.gloveboxByModel.futo = nil

-- hunger and thirst
d = FrameOS.getPlayer(2)
check(d.needs.hunger == 100 and d.needs.thirst == 100, 'a new player starts fed and watered')
FrameOS.needsTick()
check(math.abs(d.needs.hunger - (100 - Config.needs.hungerPerMinute)) < 1e-9, 'one minute lowers hunger')
check(math.abs(d.needs.thirst - (100 - Config.needs.thirstPerMinute)) < 1e-9, 'one minute lowers thirst (faster than hunger)')
d.needs.hunger = 10; d.needs.thirst = 10
d.bag = { burger = 1, water = 1, bandage = 1 }
r = ask(2, 'useItem', 'burger')
check(r.result.ok and d.needs.hunger == 10 + Items.burger.food and d.bag.burger == nil, 'a burger raises hunger and is used up')
check(r.result.food == Items.burger.food, 'the answer says what it fed (so the screen can animate)')
r = ask(2, 'useItem', 'water')
check(r.result.ok and d.needs.thirst == 10 + Items.water.drink, 'water raises thirst')
d.needs.hunger = 100; d.needs.thirst = 100
d.bag = { burger = 1, water = 1 }
r = ask(2, 'useItem', 'burger')
check(r.result.ok == false and d.bag.burger == 1, 'food is refused (and kept) when you are not hungry')
r = ask(2, 'useItem', 'water')
check(r.result.ok == false and d.bag.water == 1, 'a drink is refused (and kept) when you are not thirsty')
d.needs.hunger = 99.0; d.bag = { burger = 1 }
r = ask(2, 'useItem', 'burger')
check(r.result.ok == false, 'almost full also counts as not hungry')
d.needs.hunger = 90; d.needs.thirst = 90
r = ask(2, 'useItem', 'burger')
check(r.result.ok and d.needs.hunger == 100, 'needs never go above 100')
for i = 1, 200 do FrameOS.needsTick() end
check(d.needs.hunger == 0 and d.needs.thirst == 0, 'needs never go below 0')
check(not (d.needs.hunger < 0), '... (clamped)')
r = ask(2, 'hospitalBill')
check(d.needs.hunger == Config.needs.afterDeath and d.needs.thirst == Config.needs.afterDeath, 'waking up at the hospital lifts needs to the set level')
d.needs.hunger = 90
ask(2, 'hospitalBill')
check(d.needs.hunger == 90, 'waking up never lowers needs')
r = ask(2, 'admin', 'setneeds', 20, 5)
check(r.result.ok and d.needs.hunger == 20 and d.needs.thirst == 5, 'admin /setneeds works')
r = ask(2, 'admin', 'setneeds', 500, -3)
check(d.needs.hunger == 100 and d.needs.thirst == 0, 'admin /setneeds is clamped to 0-100')

-- a half-written needs table in an old file does not break the load
fire('playerDropped', 2)
files['playerdata/license_bbb.json'] = json.encode({ cash = 10, needs = { hunger = 'x' } })
fire('frameos:join', 2)
check(FrameOS.getPlayer(2).needs.hunger == 100 and FrameOS.getPlayer(2).needs.thirst == 100, 'a damaged needs table is repaired on load')

-- the character
local function sample()
    local f = {}
    for i = 1, 20 do f[i] = 0.5 end
    return {
        name = { first = '  jASON ', last = "o'neil-smith" }, sex = 'm',
        look = { mother = 30, father = 5, shapeMix = 0.3, skinMix = 0.7, features = f,
            overlays = { { id = 2, style = 5, opacity = 0.8, color = 4 }, { id = 4, style = 99, opacity = 1, color = 0 }, { id = 77, style = 1 } },
            hair = { style = 12, color = 3, highlight = 9 }, eyes = 6 },
        outfit = { parts = { { id = 11, drawable = 0, texture = 1 }, { id = 0, drawable = 5, texture = 0 }, { id = 2, drawable = 5, texture = 0 } }, props = { { id = 0, drawable = -1, texture = 0 } } },
    }
end
local c, why = FrameOS.cleanCharacter(sample())
check(c and c.name.first == 'Jason' and c.name.last == "O'neil-Smith", 'names are trimmed and capitalised')
check(c.look.mother == 30 and c.look.father == 5 and c.look.eyes == 6, 'valid numbers are kept')
check(#c.look.overlays == 1 and c.look.overlays[1].id == 2, 'an overlay style that does not exist, and an unknown overlay, are dropped')
check(#c.outfit.parts == 1 and c.outfit.parts[1].id == 11, 'head (0) and hair (2) are not outfit slots')
local bad = sample(); bad.look.mother = 9999; bad.look.father = -5; bad.look.shapeMix = 5; bad.look.features[3] = 0/0; bad.look.features[4] = 'x'; bad.look.hair.color = 1e9
c = FrameOS.cleanCharacter(bad)
check(c.look.mother == 21 and c.look.father == 0 and c.look.shapeMix == 1, 'a parent that is not in the list becomes the first in the list, mixes are clamped')
bad = sample(); bad.look.mother = 45; bad.look.father = 44; local c2 = FrameOS.cleanCharacter(bad)
check(c2.look.mother == 45 and c2.look.father == 44, 'the special parents (mother 45, fathers 42 to 44) are allowed')
bad = sample(); bad.look.mother = 16; bad.look.father = 25; c2 = FrameOS.cleanCharacter(bad)
check(c2.look.mother == 21 and c2.look.father == 0, 'a father number used as a mother (and the reverse) is not allowed')
bad = sample(); bad.look.mother = 31; bad.look.father = 16; c2 = FrameOS.cleanCharacter(bad)
check(c2.look.mother == 31 and c2.look.father == 16, 'mother 31 with father 16 is allowed')
check(c.look.features[3] == 0 and c.look.features[4] == 0 and #c.look.features == 20, 'NaN and text in a slider become 0, always 20 sliders')
check(c.look.hair.color == 63, 'hair color is clamped')
bad = sample(); bad.sex = 'x'; check(FrameOS.cleanCharacter(bad) == nil, 'bad sex is refused')
bad = sample(); bad.name.first = 'A'; check(FrameOS.cleanCharacter(bad) == nil, 'a one letter name is refused')
bad = sample(); bad.name.last = 'Bob<script>'; check(FrameOS.cleanCharacter(bad) == nil, 'symbols in a name are refused')
bad = sample(); bad.name.first = string.rep('a', 40); check(FrameOS.cleanCharacter(bad) == nil, 'a long name is refused')
check(FrameOS.cleanCharacter('x') == nil and FrameOS.cleanCharacter({}) == nil, 'junk is refused')

fire('frameos:join', 3)   -- a normal (non admin) player
d = FrameOS.getPlayer(3)
check(d.character == nil, 'a new player has no character')
r = ask(3, 'saveCharacter', sample())
check(r.result.ok and d.character and d.character.name.first == 'Jason', 'a player with no character can save one')
check(FrameOS.characterName(3) == "Jason O'neil-Smith", 'FrameOS.characterName gives the full name')
r = ask(3, 'saveCharacter', sample())
check(r.result.ok == false, 'a normal player cannot change an existing character')
r = ask(2, 'saveCharacter', sample())
check(r.result.ok and FrameOS.getPlayer(2).character, 'an admin can (the /creator test command)')
Config.testCommands = false
r = ask(2, 'saveCharacter', sample())
check(r.result.ok == false, 'even an admin cannot once test commands are off')
Config.testCommands = true

-- local.lua
check(Config.admins[1] == 'license:bbb' and Config.admins[2] == 'license:ccc', 'local.lua sets the admins')
check(Config.somethingElse == nil, 'local.lua can only change admins, importEnabled and importCashMax')

-- /saveclothes
r = ask(3, 'saveClothes', { parts = { { id = 11, drawable = 4, texture = 1 } }, props = {} })
check(r.result.ok == false, 'a normal player cannot use saveClothes')
r = ask(2, 'saveClothes', { parts = { { id = 11, drawable = 4, texture = 1 }, { id = 0, drawable = 9, texture = 0 } }, props = { { id = 6, drawable = 2, texture = 0 } } })
check(r.result.ok and #FrameOS.getPlayer(2).character.outfit.parts == 1 and FrameOS.getPlayer(2).character.outfit.parts[1].drawable == 4, 'an admin can save what they wear (head slot dropped)')
check(FrameOS.getPlayer(2).character.name.first == 'Jason', '... and the rest of the character is untouched')

-- clothing stores, barbers, wardrobes
local store, barber, wspot = Config.clothingStores[1], Config.barbers[1], Config.wardrobes[1]
local pc = FrameOS.getPlayer(3)
local function put(spot) pos.x, pos.y, pos.z = spot.x, spot.y, spot.z end
local function newOutfit(top, hat)
    return { parts = { { id = 11, drawable = top, texture = 0 }, { id = 4, drawable = 3, texture = 0 }, { id = 2, drawable = 99, texture = 0 } },
             props = { { id = 0, drawable = hat, texture = 0 } } }
end
pc.cash = 1000
put({ x = 0, y = 0, z = 0 })
r = ask(3, 'buyClothes', 1, newOutfit(7, 3))
check(r.result.ok == false and pc.cash == 1000, 'clothing store: refused when you are not there')
put(store)
r = ask(3, 'buyClothes', 1, newOutfit(7, 3))
check(r.result.ok and pc.cash == 1000 - Config.clothesPrice, 'clothing store: bought, flat price taken')
local function find(list, id) for _, e in ipairs(list) do if e.id == id then return e end end end
check(find(pc.character.outfit.parts, 11).drawable == 7 and find(pc.character.outfit.props, 0).drawable == 3, '... and the new clothes are saved')
check(find(pc.character.outfit.parts, 2) == nil, '... a slot that is not for sale (hair) is not taken from the client')
r = ask(3, 'buyClothes', 1, newOutfit(7, 3))
check(r.result.ok == false and r.result.why == 'Nothing changed' and pc.cash == 1000 - Config.clothesPrice, 'clothing store: no charge when nothing changed')
pc.cash = 10
r = ask(3, 'buyClothes', 1, newOutfit(8, 3))
check(r.result.ok == false and find(pc.character.outfit.parts, 11).drawable == 7, 'clothing store: too poor, nothing changes')
pc.cash = 1000
r = ask(3, 'buyClothes', 99, newOutfit(8, 3))
check(r.result.ok == false, 'clothing store: a store number that does not exist is refused')
r = ask(3, 'buyClothes', 1, 'junk')
check(r.result.ok == false, 'clothing store: junk is refused')

local oldLook = FrameOS.cleanLook(pc.character.look)
put(barber)
local newLook = FrameOS.cleanLook(pc.character.look)
newLook.hair.style = 5; newLook.eyes = 4
newLook.overlays = { { id = 1, style = 2, opacity = 0.5, color = 3 }, { id = 0, style = 9, opacity = 1.0, color = 0 } }
newLook.mother = 30; newLook.features[1] = 0.9
local cashBefore = pc.cash
r = ask(3, 'buyBarber', 1, newLook)
check(r.result.ok and pc.cash == cashBefore - Config.barberPrice, 'barber: paid')
check(pc.character.look.hair.style == 5 and pc.character.look.eyes == 4, 'barber: hair and eyes changed')
local beard = nil
for _, o in ipairs(pc.character.look.overlays) do if o.id == 1 then beard = o end end
check(beard and beard.style == 2, 'barber: facial hair changed')
local blemish = nil
for _, o in ipairs(pc.character.look.overlays) do if o.id == 0 then blemish = o end end
check(blemish == nil, 'barber: skin overlays are not taken from the client')
check(pc.character.look.mother == oldLook.mother and pc.character.look.features[1] == oldLook.features[1], 'barber: parents and face shape stay the same')
cashBefore = pc.cash
r = ask(3, 'buyBarber', 1, newLook)
check(r.result.ok == false and pc.cash == cashBefore, 'barber: no charge when nothing changed')
put(store)
newLook.hair.style = 6
r = ask(3, 'buyBarber', 1, newLook)
check(r.result.ok == false, 'barber: refused when you are at a clothing store instead')

put(wspot)
r = ask(3, 'wardrobe', 'spot', 1, 'save', 2, { name = 'Night out', outfit = newOutfit(12, -1) })
check(r.result.ok and #pc.wardrobe == 1 and pc.wardrobe[1].slot == 2 and pc.wardrobe[1].name == 'Night out', 'wardrobe: saved into a slot')
r = ask(3, 'wardrobe', 'spot', 1, 'save', 2, { name = '<b>x</b>', outfit = newOutfit(13, -1) })
check(#pc.wardrobe == 1 and pc.wardrobe[1].name == 'Outfit 2', 'wardrobe: saving over a slot replaces it, a bad name becomes Outfit 2')
r = ask(3, 'wardrobe', 'spot', 1, 'rename', 2, 'Date night')
check(pc.wardrobe[1].name == 'Date night', 'wardrobe: rename')
r = ask(3, 'wardrobe', 'spot', 1, 'wear', 2)
check(r.result.ok and find(pc.character.outfit.parts, 11).drawable == 13, 'wardrobe: wearing a saved outfit changes your character outfit')
r = ask(3, 'wardrobe', 'spot', 1, 'wear', 4)
check(r.result.ok == false, 'wardrobe: an empty slot cannot be worn')
r = ask(3, 'wardrobe', 'spot', 1, 'save', Config.wardrobeSlots + 1, { outfit = newOutfit(1, -1) })
check(r.result.ok == false, 'wardrobe: a slot past the limit is refused')
put({ x = 0, y = 0, z = 0 })
r = ask(3, 'wardrobe', 'spot', 1, 'delete', 2)
check(r.result.ok == false and #pc.wardrobe == 1, 'wardrobe: refused when you are not there')
local house = next(Config.safehouses)
if house then
    put(Config.safehouses[house])
    r = ask(3, 'wardrobe', 'safehouse', house, 'delete', 2)
    check(r.result.ok and #pc.wardrobe == 0, 'wardrobe: works at a safehouse, delete')
end
r = ask(3, 'wardrobe', 'safehouse', 'nosuchplace', 'delete', 2)
check(r.result.ok == false, 'wardrobe: a safehouse that does not exist is refused')

-- bags
put(store); pc.cash = 5000
r = ask(3, 'buyClothes', 1, { parts = { { id = 5, drawable = 44, texture = 0 } }, props = {} })
check(r.result.ok and pc.cash == 5000 - Config.clothesPrice - Config.bags[44].price, 'bag: a capacity bag costs its extra price')
check(FrameOS.bagLimit(pc) == Config.bagWeight + Config.bags[44].extra, 'bag: the limit goes up by the bag extra')
r = ask(3, 'buyClothes', 1, { parts = { { id = 5, drawable = 3, texture = 0 } }, props = {} })
check(r.result.ok and FrameOS.bagLimit(pc) == Config.bagWeight, 'bag: a bag that is not in the table is only for looks, base limit')
pc.character.outfit.parts = { { id = 5, drawable = 45, texture = 0 } }
pc.bag = { burger = 1 }
check(FrameOS.bagLimit(pc) == Config.bagWeight + Config.bags[45].extra, 'bag: the limit comes from the saved outfit')
pc.character.outfit.parts = {}
check(FrameOS.bagLimit(pc) == Config.bagWeight and pc.bag.burger == 1, 'bag: taking it off keeps your items, limit drops back')
pc.bag = {}; pc.cash = 5000

-- the store
check(FrameOS.store.path('playerdata', 'license:ab/c.d') == 'playerdata/license_ab_c_d.json', 'store makes ids file-safe')
local data, raw = FrameOS.store.read('playerdata', 'license:nobody')
check(data == nil and raw == nil, 'store: a missing file reads as nothing')
check(FrameOS.store.write('playerdata', 'license:zzz', { a = 1 }), 'store: write works')
data, raw = FrameOS.store.read('playerdata', 'license:zzz')
check(data and data.a == 1 and raw, 'store: what was written reads back')
files['playerdata/license_zzz.json'] = 'garbage'
data, raw = FrameOS.store.read('playerdata', 'license:zzz')
check(data == nil and raw == 'garbage', 'store: an unreadable file gives raw text and no data')
FrameOS.store.copy('playerdata', 'license:zzz', '20260101', 'x')
check(files['playerdata/backups/license_zzz-20260101.json'] == 'x', 'store: copies go to backups/')
saveWorks = false
check(FrameOS.store.write('playerdata', 'license:zzz', { a = 2 }) == false, 'store: a failed write says so')
saveWorks = true

-- buying
d.cash = 5
r = ask(2, 'buyItem', 'nosuchshop', 'burger')
check(r.result.ok == false, 'unknown shop is refused')

say(fails == 0 and '\nALL PASSED' or ('\n' .. fails .. ' FAILED'))
os.exit(fails == 0 and 0 or 1)
