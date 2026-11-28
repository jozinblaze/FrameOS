-- runs the real clothing store, barber and wardrobe menus (modules/clothes.lua) against a pretend game,
-- pressing keys one frame at a time. from the frameos folder:   lua tests/clothes_test.lua
local say = print
local fails = 0
local function check(c, m) if c then say('ok   ' .. m) else say('FAIL ' .. m); fails = fails + 1 end end

Config = {}
local function run(f) local fn, e = loadfile(f); if not fn then error(e) end; return fn() end
run('config.lua'); run('data/character.lua'); run('data/clothes.lua')
Config.testCommands = true

-- ---------------------------------------------------------- the pretend game
local calls, notes, sent = {}, {}, nil
local model = 1
local justPressed, heldDown = {}, {}
local function rec(name) return function(...) calls[#calls + 1] = { name = name, ... } end end
local function vec(x, y, z) return { x = x, y = y, z = z } end
for _, n in ipairs({ 'SetPedHeadBlendData', 'SetPedFaceFeature', 'SetPedHeadOverlay', 'SetPedHeadOverlayColor',
    'SetPedComponentVariation', 'SetPedPropIndex', 'ClearPedProp', 'SetPedHairColor', 'SetPedEyeColor',
    'SetPedDefaultComponentVariation', 'FreezeEntityPosition', 'SetEntityInvincible', 'SetEntityHeading',
    'SetCamCoord', 'PointCamAtCoord', 'SetCamFov', 'SetCamActive', 'RenderScriptCams', 'DestroyCam',
    'DoScreenFadeIn', 'AddTextEntry', 'DisplayOnscreenKeyboard', 'DisableAllControlActions' }) do _G[n] = rec(n) end
local at = { x = 0, y = 0, z = 0 }
function PlayerPedId() return 100 end
function GetEntityCoords() return vector3(at.x, at.y, at.z) end
function DrawMarker() end
function GetPedDrawableVariationX() end
function GetEntityModel() return model end
function GetEntityHeading() return 0.0 end
function GetFrameTime() return 0.016 end
function GetGameTimer() return 0 end
function IsScreenFadedOut() return false end
function IsScreenFadingOut() return false end
function GetOffsetFromEntityInWorldCoords(_, x, y, z) return vec(x, y, z) end
function CreateCam() return 7 end
function vector3(x, y, z) return setmetatable({ x = x, y = y, z = z }, { __sub = function(a, b) return vector3(a.x - b.x, a.y - b.y, a.z - b.z) end, __len = function(a) return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z) end }) end
function joaat(s) return s end
function GetNumberOfPedDrawableVariations() return 80 end
function GetNumberOfPedTextureVariations() return 4 end
function GetNumberOfPedPropDrawableVariations() return 20 end
function GetNumberOfPedPropTextureVariations() return 4 end
function GetPedDrawableVariation(_, id) return id end
function GetPedTextureVariation() return 0 end
function GetPedPropIndex() return -1 end
function GetPedPropTextureIndex() return 0 end
function IsControlJustPressed(_, c) return justPressed[c] == true end
function IsControlPressed(_, c) return heldDown[c] == true end
local keyboard = {}
function UpdateOnscreenKeyboard() return 1 end
function GetOnscreenKeyboardResult() return table.remove(keyboard, 1) end
local threads = {}
function Wait() coroutine.yield() end
function CreateThread(fn) threads[#threads + 1] = coroutine.create(fn) end

FrameOS = { data = {}, loaded = true, uiHidden = false }
function FrameOS.notify(t) notes[#notes + 1] = t end
function FrameOS.drawText() end
function FrameOS.addBlip() return 1 end
function FrameOS.help() end
local requests = {}
function FrameOS.request(name, ...) requests[#requests + 1] = { name = name, ... }; return { ok = true } end
function FrameOS.onSpawn() end
function FrameOS.command() end
function FrameOS.testCommand() end
function FrameOS.setModel(m) model = m; return true end
run('modules/menu.lua'); run('modules/character.lua')
FrameOS.data = { character = {
    name = { first = 'Jason', last = 'Blazze' }, sex = 'm',
    look = { mother = 21, father = 0, shapeMix = 0.5, skinMix = 0.5, features = {}, overlays = {}, hair = { style = 1, color = 2, highlight = 3 }, eyes = 0 },
    outfit = { parts = { { id = 11, drawable = 11, texture = 0 } }, props = {} } }, wardrobe = {} }
FrameOS.loaded = true
run('modules/clothes.lua')

local function frames(n) for _ = 1, n do for _, co in ipairs(threads) do if coroutine.status(co) ~= 'dead' then assert(coroutine.resume(co)) end end end end
local function tap(control) justPressed[control] = true; frames(1); justPressed[control] = nil; frames(4) end
local UP, DOWN, LEFT, RIGHT, ENTER, BACK, E = 172, 173, 174, 175, 191, 177, 38
local function last(name) for i = #calls, 1, -1 do if calls[i].name == name then return calls[i] end end end

-- far from everything: nothing opens, even with E pressed
at = { x = 0, y = 0, z = 0 }
frames(3); tap(E)
check(FrameOS.uiHidden == false and #requests == 0, 'far from every place, E does nothing')

-- at a clothing store
local store = Config.clothingStores[1]
at = { x = store.x, y = store.y, z = store.z }
frames(300); tap(E)
check(FrameOS.uiHidden == true, 'E at a clothing store opens the menu')
tap(RIGHT)   -- first row (Hat): None -> 0
check(last('SetPedPropIndex') ~= nil, 'changing a clothing row shows it on the ped')
heldDown[21] = true; tap(DOWN); heldDown[21] = nil
tap(UP); tap(UP)   -- wraps to Buy
tap(ENTER)
check(requests[#requests].name == 'buyClothes' and requests[#requests][1] == 1, 'Buy asks the server for this store')
local sentOutfit = requests[#requests][2]
check(sentOutfit and sentOutfit.props and sentOutfit.props[1] and sentOutfit.props[1].id == 0 and sentOutfit.props[1].drawable == 0, 'the changed hat is in what is sent')
frames(10)
check(FrameOS.uiHidden == false, 'the screen comes back after buying')

-- leave a store without buying
at = { x = store.x, y = store.y, z = store.z }
frames(5); tap(E); local count = #requests
tap(BACK)
frames(10)
check(#requests == count and FrameOS.uiHidden == false, 'Backspace leaves without buying')

-- at a barber
local barber = Config.barbers[1]
at = { x = barber.x, y = barber.y, z = barber.z }
frames(5); tap(E)
check(FrameOS.uiHidden == true, 'E at a barber opens the menu')
tap(RIGHT)   -- hair style
tap(UP); tap(ENTER)   -- Pay
check(requests[#requests].name == 'buyBarber' and requests[#requests][2].hair.style == 2, 'Pay sends the new hair style')
frames(10)

-- at a wardrobe, save into slot 1
local w = Config.wardrobes[1]
at = { x = w.x, y = w.y, z = w.z }
frames(5); tap(E)
check(FrameOS.uiHidden == true, 'E at a wardrobe opens the menu')
tap(ENTER)           -- slot 1
keyboard = { 'Casual' }
tap(ENTER)           -- save what I am wearing
local r = requests[#requests]
check(r.name == 'wardrobe' and r[1] == 'spot' and r[2] == 1 and r[3] == 'save' and r[4] == 1 and r[5].name == 'Casual', 'saving sends the slot and the name')
tap(BACK); tap(BACK)
frames(10)
check(FrameOS.uiHidden == false, 'the wardrobe closes')

-- the safehouse key
CreateThread(function() FrameOS.openSafehouseWardrobe('beach') end)
frames(5)
check(FrameOS.uiHidden == true, 'the safehouse wardrobe opens')
tap(BACK); frames(10)

say(fails == 0 and '\nALL PASSED' or ('\n' .. fails .. ' FAILED'))
os.exit(fails == 0 and 0 or 1)
