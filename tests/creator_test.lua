-- runs the real creator menu (modules/creator.lua and modules/character.lua) against a pretend game,
-- pressing keys one frame at a time. from the frameos folder:   lua tests/creator_test.lua
local say = print
local fails = 0
local function check(c, m) if c then say('ok   ' .. m) else say('FAIL ' .. m); fails = fails + 1 end end

Config = {}
local function run(f) local fn, e = loadfile(f); if not fn then error(e) end; return fn() end
run('config.lua'); run('data/character.lua')
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
function PlayerPedId() return 100 end
function GetEntityModel() return model end
function GetEntityHeading() return 0.0 end
function GetFrameTime() return 0.016 end
function GetGameTimer() return 0 end
function IsScreenFadedOut() return false end
function IsScreenFadingOut() return false end
function GetOffsetFromEntityInWorldCoords(_, x, y, z) return vec(x, y, z) end
function CreateCam() return 7 end
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
local co
function Wait() coroutine.yield() end
function CreateThread(fn) co = coroutine.create(fn) end

FrameOS = { data = {}, loaded = true, uiHidden = false }
function FrameOS.notify(t) notes[#notes + 1] = t end
function FrameOS.drawText() end
function FrameOS.onSpawn() end
function FrameOS.command() end
function FrameOS.testCommand() end
function FrameOS.setModel(m) model = m; return true end
function FrameOS.request(name, payload) if name == 'saveCharacter' then sent = payload end return { ok = true } end
run('modules/menu.lua'); run('modules/character.lua'); run('modules/creator.lua')

-- ---------------------------------------------------------- driving it
local menu = coroutine.create(function() return FrameOS.openCreator(false) end)
local function frames(n) for _ = 1, n do if coroutine.status(menu) ~= 'dead' then assert(coroutine.resume(menu)) end end end
local function tap(control)
    justPressed[control] = true; frames(1); justPressed[control] = nil
    frames(4)    -- lets any waits inside (keyboard box, key repeat) finish
end
local UP, DOWN, LEFT, RIGHT, ENTER, BACK = 172, 173, 174, 175, 191, 177
local function last(name) for i = #calls, 1, -1 do if calls[i].name == name then return calls[i] end end end

frames(3)
check(FrameOS.uiHidden == true, 'the HUD text hides while the creator is open')
check(model == 'mp_m_freemode_01', 'a new character starts as the male freemode ped')
check(last('RenderScriptCams')[1] == true, 'the camera takes over')

tap(UP); tap(ENTER)   -- Up wraps to Finish; no name yet
check(notes[#notes] == 'Set your name first' and sent == nil, 'Finish is blocked until a name is set')
tap(DOWN)             -- back to Name
keyboard = { 'jason', 'blazze' }
tap(ENTER)
tap(DOWN); tap(RIGHT)  -- Gender
check(model == 'mp_f_freemode_01', 'Gender change switches to the female freemode ped')
tap(DOWN); tap(ENTER)  -- Parents
tap(RIGHT)
check(last('SetPedHeadBlendData')[2] == 22, 'Mother changes the head blend (mother face 22)')
for _ = 1, 20 do tap(RIGHT) end   -- 21 steps in all: past 41, to the special mother 45
check(last('SetPedHeadBlendData')[2] == 45, 'the Mother row reaches the special mother 45 at the end of the list')
tap(RIGHT)
check(last('SetPedHeadBlendData')[2] == 21, '... and wraps back to the start')
tap(RIGHT)
tap(DOWN); tap(DOWN); tap(RIGHT)
check(math.abs(last('SetPedHeadBlendData')[8] - 0.55) < 1e-9, 'the face mix slider moves 5%')
tap(BACK)
tap(DOWN); tap(ENTER)  -- Face
tap(RIGHT); tap(RIGHT)
local feature
for i = #calls, 1, -1 do if calls[i].name == 'SetPedFaceFeature' and calls[i][2] == 0 then feature = calls[i]; break end end
check(feature and math.abs(feature[3] - 0.2) < 1e-9, 'a face slider moves in steps of 0.1 (two presses = 0.2)')
tap(BACK)
tap(DOWN); tap(DOWN); tap(ENTER)   -- Hair and eyes (Skin is skipped: down x2 from Face)
tap(DOWN); tap(DOWN); tap(DOWN); tap(DOWN)   -- hair style, color, highlights, eye color, eyebrows
tap(RIGHT)
local overlay
for i = #calls, 1, -1 do if calls[i].name == 'SetPedHeadOverlay' and calls[i][2] == 2 then overlay = calls[i]; break end end
check(overlay and overlay[3] == 0, 'Eyebrows style None -> 0 turns the overlay on')
tap(DOWN); tap(RIGHT)    -- strength row
tap(BACK)
-- main: Hair row is selected; go to the outfit row (two rows past Makeup) and change it
tap(DOWN); tap(DOWN); tap(RIGHT)
tap(DOWN); tap(ENTER)   -- Finish
check(sent ~= nil, 'Finish sends the character to the server')
check(sent.name.first == 'jason' and sent.name.last == 'blazze' and sent.sex == 'f', 'the name and sex are in the payload')
check(sent.look.mother == 22 and #sent.look.features == 20, 'the look is in the payload')
local hasBrows = false
for _, o in ipairs(sent.look.overlays) do if o.id == 2 then hasBrows = true end end
check(hasBrows and type(sent.look.overlays) == 'table' and sent.look.overlays[1].id ~= nil, 'overlays are sent as a list')
check(sent.outfit and #sent.outfit.parts == #Config.character.outfitParts, 'the outfit is read from the ped')
frames(5)
check(coroutine.status(menu) == 'dead', 'the creator closes after saving')
check(FrameOS.uiHidden == false, 'the HUD text comes back')

-- applying a saved character puts the right model on and clamps numbers
calls = {}; model = 1
local c = { sex = 'f', look = sent.look, outfit = { parts = { { id = 11, drawable = 9999, texture = 99 } }, props = {} } }
check(FrameOS.applyCharacter(c) == true and model == 'mp_f_freemode_01', 'applyCharacter becomes the saved sex')
local top
for _, call in ipairs(calls) do if call.name == 'SetPedComponentVariation' and call[2] == 11 then top = call end end
check(top and top[3] == 79 and top[4] == 3, 'a drawable or texture number that is too big is clamped to the biggest real one')

-- a saved list of overlays is matched by id, not by position
calls = {}
local listLook = { mother = 21, father = 0, shapeMix = 0.5, skinMix = 0.5, features = {}, hair = { style = 0, color = 0, highlight = 0 }, eyes = 0,
    overlays = { { id = 4, style = 3, opacity = 0.5, color = 1 }, { id = 2, style = 1, opacity = 1.0, color = 2 } } }
FrameOS.applyLook(100, listLook)
local seen = {}
for _, call in ipairs(calls) do if call.name == 'SetPedHeadOverlay' then seen[call[2]] = call[3] end end
check(seen[2] == 1 and seen[4] == 3 and seen[0] == 255, 'overlays saved as a list are applied by id (and the ones not in the list are turned off)')

-- the top goes on before the undershirt and the arms (the game can reset them when a top goes on)
calls = {}
FrameOS.applyOutfit(100, { parts = { { id = 3, drawable = 4, texture = 0 }, { id = 4, drawable = 1, texture = 0 }, { id = 8, drawable = 5, texture = 0 }, { id = 11, drawable = 9, texture = 0 } }, props = {} })
local order = {}
for _, call in ipairs(calls) do if call.name == 'SetPedComponentVariation' then order[#order + 1] = call[2] end end
check(table.concat(order, ',') == '11,8,3,4', 'applyOutfit puts the top on first, then undershirt, then arms')

say(fails == 0 and '\nALL PASSED' or ('\n' .. fails .. ' FAILED'))
os.exit(fails == 0 and 0 or 1)
