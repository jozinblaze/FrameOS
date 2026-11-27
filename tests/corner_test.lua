-- checks the top right text stacking in core.lua (FrameOS.corner). from the frameos folder:
--   lua tests/corner_test.lua
local say = print
local fails = 0
local function check(c, m) if c then say('ok   ' .. m) else say('FAIL ' .. m); fails = fails + 1 end end
Config = {}
local function run(f) local fn, e = loadfile(f); if not fn then error(e) end; return fn() end
run('config.lua')

local threads, drawn, texts = {}, {}, {}
function CreateThread(fn) threads[#threads + 1] = coroutine.create(fn) end
function Wait() coroutine.yield() end
function AddEventHandler() end
function RegisterCommand() end
function SetResourceKvp() end
function joaat(s) return s end
for _, n in ipairs({ 'SetTextFont','SetTextScale','SetTextColour','SetTextOutline','SetTextRightJustify','SetTextWrap','BeginTextCommandDisplayText' }) do _G[n] = function() end end
function AddTextComponentSubstringPlayerName(t) texts[#texts + 1] = t end
function EndTextCommandDisplayText(x, y) drawn[#drawn + 1] = y end
run('core.lua')

local show = { cash = true, job = false, needs = false }
FrameOS.corner(function() if show.cash then return '$100', { 1, 1, 1 }, 0.6 end end)
FrameOS.corner(function() if show.job then return 'Courier', { 1, 1, 1 }, 0.4 end end)
FrameOS.corner(function() if show.needs then return 'Hungry', { 1, 1, 1 }, 0.4 end end)
local function frame()
    drawn, texts = {}, {}
    for _, co in ipairs(threads) do if coroutine.status(co) ~= 'dead' then assert(coroutine.resume(co)) end end
end
frame(); frame()
check(#drawn == 1 and math.abs(drawn[1] - 0.03) < 1e-9, 'only cash: drawn at the top')
show.job, show.needs = true, true; frame()
check(#drawn == 3 and math.abs(drawn[2] - 0.08) < 1e-9 and math.abs(drawn[3] - 0.11) < 1e-9, 'cash, job and needs stack at 0.03, 0.08, 0.11')
show.job = false; frame()
check(#drawn == 2 and math.abs(drawn[2] - 0.08) < 1e-9, 'with no job the needs line moves up under the cash')
say(fails == 0 and '\nALL PASSED' or ('\n' .. fails .. ' FAILED'))
os.exit(fails == 0 and 0 or 1)
