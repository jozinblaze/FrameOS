-- loads modules/needs.lua with a pretend game and checks the regen and damage rules.
-- from the frameos folder:   lua tests/client_test.lua
local say = print
local fails = 0
local function check(c, m) if c then say('ok   ' .. m) else say('FAIL ' .. m); fails = fails + 1 end end

Config = {}
local function run(f) local fn, e = loadfile(f); if not fn then error(e) end; return fn() end
run('config.lua'); run('data/items.lua')
Config.testCommands = true

local multiplier, health, notes, commands = nil, 150, {}, {}
local threads = {}
function CreateThread(fn) threads[#threads + 1] = coroutine.create(fn) end
local waits = 0
function Wait() waits = waits + 1; coroutine.yield() end
function PlayerId() return 1 end
function PlayerPedId() return 1 end
function IsEntityDead() return false end
function IsPedInAnyVehicle() return false end
function SetPlayerHealthRechargeMultiplier(_, m) multiplier = m end
function GetEntityHealth() return health end
function SetEntityHealth(_, h) health = h end
FrameOS = { data = { needs = { hunger = 100, thirst = 100 }, bag = {} } }
function FrameOS.notify(t) notes[#notes + 1] = t end
function FrameOS.drawText() end
for _, n in ipairs({ 'SetTextFont','SetTextScale','SetTextColour','SetTextOutline','SetTextRightJustify','SetTextWrap','BeginTextCommandDisplayText','AddTextComponentSubstringPlayerName','EndTextCommandDisplayText' }) do _G[n] = function() end end
function FrameOS.command(n, h, f) commands[n] = f end
FrameOS.testCommand = FrameOS.command
function FrameOS.request() end
run('modules/needs.lua')

local function step(n)   -- runs every thread n times (each Wait is one pass)
    for _ = 1, n do
        for _, co in ipairs(threads) do if coroutine.status(co) ~= 'dead' then assert(coroutine.resume(co)) end end
    end
end
local function setNeeds(h, t) FrameOS.data.needs = { hunger = h, thirst = t } end

step(2); check(multiplier == Config.needs.regenFed, 'fed: normal regen')
setNeeds(40, 90); step(1); check(multiplier == Config.needs.regenSlow, 'getting low: slower regen')
setNeeds(90, 20); step(1); check(multiplier == 0.0, 'very low (either one): no regen')
check(health == 150, 'no damage while above 0')
setNeeds(0, 80); health = 150
step(1 + 3 * math.ceil(Config.needs.damageEvery / 2000)); check(health < 150, 'empty: you lose health')
health = Config.needs.floor; step(10); check(health == Config.needs.floor, 'empty: never below the floor (cannot kill)')
setNeeds(100, 100); step(1); check(multiplier == Config.needs.regenFed, 'eating brings regen back')

local n = #notes
setNeeds(20, 100); step(1); check(notes[#notes] == 'You are getting hungry', 'warns once when low')
local count = #notes; step(2); check(#notes == count, '... and not again every check')
setNeeds(0, 100); step(1); check(notes[#notes] == 'You are starving', 'warns when empty')
commands.needs(); check(notes[#notes]:find('Hunger 0%%'), '/needs prints the numbers')

say(fails == 0 and '\nALL PASSED' or ('\n' .. fails .. ' FAILED'))
os.exit(fails == 0 and 0 or 1)
