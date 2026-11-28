-- clothes: clothing stores, barbers and wardrobes (the places are in data/clothes.lua).
-- walk into a circle and press E. the server decides everything (server/clothes.lua): where you
-- stand, what changed, the price. this file is the menus and the circles.
--   clothing store   pick clothes slot by slot, Buy at the bottom (one flat price, only if you changed something)
--   barber           hair, hair color, eyes, facial hair, eyebrows and makeup, same idea
--   wardrobe         save what you wear into a slot, wear a saved outfit, rename or delete (free).
--                    wardrobes are at the spots in data/clothes.lua and at safehouses (press H there).
-- the menu itself (rows, camera, controls) is in modules/menu.lua.

local M = FrameOS.menu
local C = Config.character

local function clamp(n, low, high)
    return math.max(low, math.min(high, n))
end

local busy = false   -- one menu at a time

-- ---------------------------------------------------------------- the screen around a menu

-- freezes you, starts the camera, runs fn, then puts everything back
local function withCamera(fn)
    busy = true
    local ped = PlayerPedId()
    FrameOS.uiHidden = true
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    local camera = M.camera()
    local ok, err = pcall(fn, camera)
    camera.close()
    local after = PlayerPedId()
    FreezeEntityPosition(after, false)
    SetEntityInvincible(after, false)
    FrameOS.uiHidden = false
    busy = false
    if not ok then
        print('[FrameOS] clothes menu error: ' .. tostring(err))
    end
end

-- ---------------------------------------------------------------- clothing store

local function entryOf(list, id)
    for _, entry in ipairs(list) do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

local function openClothingStore(index)
    local saved = FrameOS.data.character
    if not saved then
        FrameOS.notify('Make your character first')
        return
    end
    withCamera(function(camera)
        local ped = PlayerPedId()
        FrameOS.applyCharacter(saved)
        ped = PlayerPedId()
        FreezeEntityPosition(ped, true)
        SetEntityInvincible(ped, true)

        -- what you wear now, changed by the rows. only the slots in Config.clothesSlots are shown.
        local outfit = FrameOS.readOutfitParts(PlayerPedId())
        local function slotEntry(slot)
            local list = slot.kind == 'part' and outfit.parts or outfit.props
            local entry = entryOf(list, slot.id)
            if not entry then
                entry = { id = slot.id, drawable = slot.kind == 'part' and 0 or -1, texture = 0 }
                table.insert(list, entry)
            end
            return entry
        end
        local function show()
            FrameOS.applyOutfit(PlayerPedId(), outfit)
        end

        local done, leave = false, false
        local pages = { main = { title = 'Clothing store  (' .. (Config.clothesPrice) .. ' cash)', build = function()
            local out = {}
            for _, slot in ipairs(Config.clothesSlots) do
                local entry = slotEntry(slot)
                local low = slot.kind == 'prop' and -1 or 0
                local count
                if slot.kind == 'part' then
                    count = GetNumberOfPedDrawableVariations(PlayerPedId(), slot.id)
                else
                    count = GetNumberOfPedPropDrawableVariations(PlayerPedId(), slot.id)
                end
                if count > 0 then
                    table.insert(out, M.choiceRow(slot.name, function() return entry.drawable end,
                        function(v) entry.drawable = v; entry.texture = 0; show() end,
                        low, count - 1, function(v) return v < 0 and 'None' or tostring(v) end))
                    if entry.drawable >= 0 then
                        local textures
                        if slot.kind == 'part' then
                            textures = GetNumberOfPedTextureVariations(PlayerPedId(), slot.id, entry.drawable)
                        else
                            textures = GetNumberOfPedPropTextureVariations(PlayerPedId(), slot.id, entry.drawable)
                        end
                        if textures > 1 then
                            table.insert(out, M.choiceRow('   Variant', function() return entry.texture end,
                                function(v) entry.texture = v; show() end, 0, textures - 1))
                        end
                    end
                end
            end
            table.insert(out, { label = 'Buy', text = function() return '' end, enter = function()
                local result = FrameOS.request('buyClothes', index, outfit)
                if result then
                    done = true
                end
            end })
            return out
        end } }

        M.run({
            pages = pages, camera = camera,
            finished = function() return done or leave end,
            root = function() leave = true end,
        })
        if leave then
            FrameOS.applyCharacter(saved)   -- walked away without buying: back to what you wore
        else
            FrameOS.notify('Nice outfit')
        end
    end)
end

-- ---------------------------------------------------------------- barber

local function openBarber(index)
    local saved = FrameOS.data.character
    if not saved then
        FrameOS.notify('Make your character first')
        return
    end
    withCamera(function(camera)
        camera.set('face')
        FrameOS.applyCharacter(saved)
        FreezeEntityPosition(PlayerPedId(), true)
        SetEntityInvincible(PlayerPedId(), true)

        -- a working copy of your look: overlays keyed by id while editing
        local look = {
            mother = saved.look.mother, father = saved.look.father,
            shapeMix = saved.look.shapeMix, skinMix = saved.look.skinMix,
            features = saved.look.features,
            overlays = {},
            hair = { style = saved.look.hair.style, color = saved.look.hair.color, highlight = saved.look.hair.highlight },
            eyes = saved.look.eyes,
        }
        for _, o in ipairs(saved.look.overlays or {}) do
            look.overlays[o.id] = { style = o.style, opacity = o.opacity, color = o.color }
        end
        local function show()
            FrameOS.applyLook(PlayerPedId(), look)
        end
        local function defById(id)
            for _, def in ipairs(C.overlays) do
                if def.id == id then return def end
            end
        end

        local function overlayRows(rows, def)
            local overlays = look.overlays
            table.insert(rows, M.choiceRow(def.name, function()
                return overlays[def.id] and overlays[def.id].style or -1
            end, function(value)
                if value < 0 then
                    overlays[def.id] = nil
                else
                    overlays[def.id] = overlays[def.id] or { style = value, opacity = 1.0, color = 0 }
                    overlays[def.id].style = value
                end
                show()
            end, -1, def.max, function(value) return value < 0 and 'None' or tostring(value) end))
            if overlays[def.id] then
                table.insert(rows, M.sliderRow('   Strength', function() return overlays[def.id].opacity end,
                    function(value) overlays[def.id].opacity = value; show() end, 0.0, 1.0, 0.1,
                    function(v) return string.format('%d%%', math.floor(v * 100 + 0.5)) end))
                if def.color then
                    table.insert(rows, M.choiceRow('   Color', function() return overlays[def.id].color end,
                        function(value) overlays[def.id].color = value; show() end, 0, C.hairColors))
                end
            end
        end

        local done, leave = false, false
        local pages = { main = { title = 'Barber  (' .. Config.barberPrice .. ' cash)', build = function()
            local rows = {
                M.choiceRow('Hair style', function() return look.hair.style end,
                    function(v) look.hair.style = v; show() end, 0,
                    math.max(0, GetNumberOfPedDrawableVariations(PlayerPedId(), 2) - 1)),
                M.choiceRow('Hair color', function() return look.hair.color end,
                    function(v) look.hair.color = v; show() end, 0, C.hairColors),
                M.choiceRow('Highlights', function() return look.hair.highlight end,
                    function(v) look.hair.highlight = v; show() end, 0, C.hairColors),
                M.choiceRow('Eye color', function() return look.eyes end,
                    function(v) look.eyes = v; show() end, 0, C.eyeColors),
            }
            for _, id in ipairs(Config.barberOverlays) do
                local def = defById(id)
                if def then overlayRows(rows, def) end
            end
            table.insert(rows, { label = 'Pay', text = function() return '' end, enter = function()
                local list = {}
                for _, def in ipairs(C.overlays) do
                    local o = look.overlays[def.id]
                    if o then
                        table.insert(list, { id = def.id, style = o.style, opacity = o.opacity, color = o.color })
                    end
                end
                local payload = {
                    mother = look.mother, father = look.father, shapeMix = look.shapeMix, skinMix = look.skinMix,
                    features = look.features, overlays = list, hair = look.hair, eyes = look.eyes,
                }
                if FrameOS.request('buyBarber', index, payload) then
                    done = true
                end
            end })
            return rows
        end } }

        M.run({
            pages = pages, camera = camera,
            finished = function() return done or leave end,
            root = function() leave = true end,
        })
        if leave then
            FrameOS.applyCharacter(saved)
        else
            FrameOS.notify('Looking sharp')
        end
    end)
end

-- ---------------------------------------------------------------- wardrobe

-- kind is 'spot' (ref = its number in Config.wardrobes) or 'safehouse' (ref = its name)
local function openWardrobe(kind, ref)
    local saved = FrameOS.data.character
    if not saved then
        FrameOS.notify('Make your character first')
        return
    end
    withCamera(function(camera)
        local function entryFor(slot)
            for _, entry in ipairs(FrameOS.data.wardrobe or {}) do
                if entry.slot == slot then return entry end
            end
        end
        local function ask(action, slot, arg)
            return FrameOS.request('wardrobe', kind, ref, action, slot, arg)
        end

        local leave = false
        local pages = { main = { title = 'Wardrobe', build = function()
            local rows = {}
            for slot = 1, Config.wardrobeSlots do
                local entry = entryFor(slot)
                table.insert(rows, {
                    label = entry and entry.name or ('Slot ' .. slot .. '  (empty)'),
                    text = function() return '>' end,
                    enter = function() M.openPage('slot' .. slot) end,
                })
            end
            return rows
        end } }

        for slot = 1, Config.wardrobeSlots do
            pages['slot' .. slot] = { title = 'Wardrobe slot ' .. slot, build = function()
                local entry = entryFor(slot)
                local rows = {}
                table.insert(rows, { label = 'Save what I am wearing here', text = function() return '' end, enter = function()
                    local name = entry and entry.name or nil
                    if not name then
                        name = M.askText('Outfit name', 'Outfit ' .. slot, 20)
                    end
                    if name then
                        ask('save', slot, { name = name, outfit = FrameOS.readOutfitParts(PlayerPedId()) })
                    end
                end })
                if entry then
                    table.insert(rows, { label = 'Wear it', text = function() return '' end, enter = function()
                        if ask('wear', slot) then
                            local c = FrameOS.data.character
                            if c then
                                FrameOS.applyOutfit(PlayerPedId(), c.outfit)
                            end
                            FrameOS.notify('Changed into ' .. entry.name)
                        end
                    end })
                    table.insert(rows, { label = 'Rename', text = function() return entry.name end, enter = function()
                        local name = M.askText('Outfit name', entry.name, 20)
                        if name then ask('rename', slot, name) end
                    end })
                    table.insert(rows, { label = 'Delete', text = function() return '' end, enter = function()
                        ask('delete', slot)
                        M.goBack()
                    end })
                end
                return rows
            end }
        end

        M.run({
            pages = pages, camera = camera,
            finished = function() return leave end,
            root = function() leave = true end,
        })
    end)
end

-- ---------------------------------------------------------------- the circles

local blips = {}
for _, store in ipairs(Config.clothingStores) do
    local b = FrameOS.addBlip(store.x, store.y, store.z, Config.clothesBlip.sprite, Config.clothesBlip.color, 'Clothing store')
    if b then table.insert(blips, b) end
end
for _, barber in ipairs(Config.barbers) do
    local b = FrameOS.addBlip(barber.x, barber.y, barber.z, Config.barberBlip.sprite, Config.barberBlip.color, 'Barber')
    if b then table.insert(blips, b) end
end

-- one thread for all of them: far from everything it checks twice a second
CreateThread(function()
    local places = {}
    for i, s in ipairs(Config.clothingStores) do
        table.insert(places, { x = s.x, y = s.y, z = s.z, color = { 80, 160, 255 }, text = 'Press ~INPUT_CONTEXT~ for the clothing store',
            open = function() openClothingStore(i) end })
    end
    for i, s in ipairs(Config.barbers) do
        table.insert(places, { x = s.x, y = s.y, z = s.z, color = { 255, 200, 80 }, text = 'Press ~INPUT_CONTEXT~ for the barber',
            open = function() openBarber(i) end })
    end
    for i, s in ipairs(Config.wardrobes) do
        table.insert(places, { x = s.x, y = s.y, z = s.z, color = { 160, 255, 160 }, text = 'Press ~INPUT_CONTEXT~ for your wardrobe',
            open = function() openWardrobe('spot', i) end })
    end

    while true do
        local sleep = 500
        if not busy and FrameOS.loaded then
            local coords = GetEntityCoords(PlayerPedId())
            for _, p in ipairs(places) do
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 25.0 then
                    sleep = 0
                    DrawMarker(1, p.x, p.y, p.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 1.2, 1.2, 0.5,
                        p.color[1], p.color[2], p.color[3], 140, false, false, 2, false, nil, nil, false)
                    if dist < 1.5 then
                        FrameOS.help(p.text)
                        if IsControlJustPressed(0, 38) then
                            p.open()
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- H at a safehouse opens the wardrobe there (the E and G keys are in safehouses.lua)
FrameOS.openSafehouseWardrobe = function(name)
    if not busy then
        openWardrobe('safehouse', name)
    end
end
