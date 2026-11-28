-- clothes: clothing stores, barbers and wardrobes. the server decides all of it:
--   buyClothes(store, outfit)        you must stand at that clothing store, only the slots in
--                                    Config.clothesSlots can change, a flat price is taken only if something changed
--   buyBarber(barber, look)          you must stand at that barber, only hair, eyes and the overlays in
--                                    Config.barberOverlays can change, flat price, only if something changed
--   wardrobe(kind, ref, action, ...) save / wear / rename / delete a saved outfit, free. kind is 'spot'
--                                    (a wardrobe from Config.wardrobes) or 'safehouse' (by name)
-- the places and prices are in data/clothes.lua. everything is checked again here, whatever the
-- screen says: where you stand, the numbers, the price and that you can pay. the checks on the numbers
-- themselves (FrameOS.cleanOutfit, FrameOS.cleanLook) are in server/character.lua.

local C = Config.character

local function no(why)
    return { ok = false, why = why }
end

local function near(source, x, y, z, range)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false
    end
    return #(GetEntityCoords(ped) - vector3(x, y, z)) <= range
end

local function copy(value)
    if type(value) ~= 'table' then
        return value
    end
    local result = {}
    for k, v in pairs(value) do
        result[k] = copy(v)
    end
    return result
end

-- the spot with this number in a list, if you are standing at it
local function spotAt(source, list, index, range)
    index = math.floor(tonumber(index) or 0)
    local spot = list[index]
    if spot and near(source, spot.x, spot.y, spot.z, range) then
        return spot
    end
    return nil
end

-- ---------------------------------------------------------------- outfits

local function byId(list)
    local map = {}
    for _, entry in ipairs(list or {}) do
        map[entry.id] = entry
    end
    return map
end

local function sameEntry(a, b)
    if a == nil or b == nil then
        return a == b
    end
    return a.drawable == b.drawable and a.texture == b.texture
end

-- is every slot the same in both outfits?
local function sameOutfit(a, b)
    for _, kind in ipairs({ 'parts', 'props' }) do
        local one, two = byId(a[kind]), byId(b[kind])
        for id in pairs(one) do
            if not sameEntry(one[id], two[id]) then return false end
        end
        for id in pairs(two) do
            if not sameEntry(one[id], two[id]) then return false end
        end
    end
    return true
end

-- the saved outfit, with only the slots a clothing store may change taken from what was sent
local function mergeOutfit(saved, sent)
    local merged = copy(saved)
    local parts, props = byId(merged.parts), byId(merged.props)
    local newParts, newProps = byId(sent.parts), byId(sent.props)
    for _, slot in ipairs(Config.clothesSlots) do
        if slot.kind == 'part' and newParts[slot.id] then
            parts[slot.id] = newParts[slot.id]
        elseif slot.kind == 'prop' and newProps[slot.id] then
            props[slot.id] = newProps[slot.id]
        end
    end
    merged.parts, merged.props = {}, {}
    for _, id in ipairs(C.outfitParts) do
        if parts[id] then table.insert(merged.parts, parts[id]) end
    end
    for _, id in ipairs(C.outfitProps) do
        if props[id] then table.insert(merged.props, props[id]) end
    end
    return merged
end

FrameOS.onAsk('buyClothes', function(source, index, outfit)
    local d = FrameOS.getPlayer(source)
    if not d.character then
        return no('Make your character first')
    end
    local store = spotAt(source, Config.clothingStores, index, 5.0)
    if not store then
        return no('You are not at a clothing store')
    end
    local merged = mergeOutfit(d.character.outfit, FrameOS.cleanOutfit(outfit))
    if sameOutfit(merged, d.character.outfit) then
        return no('Nothing changed')
    end
    local price = store.price or Config.clothesPrice
    if not FrameOS.takeCash(source, price, 'clothes at store ' .. math.floor(index)) then
        return no('You need ' .. price .. ' in cash')
    end
    d.character.outfit = merged
    FrameOS.markDirty(source)
    FrameOS.log('clothes', source, 'bought a new outfit for ' .. price)
    FrameOS.push(source)
    return { ok = true, price = price }
end, { every = 500 })

-- ---------------------------------------------------------------- barbers

local barberSet = {}
for _, id in ipairs(Config.barberOverlays) do
    barberSet[id] = true
end

local function overlayMap(list)
    local map = {}
    for _, entry in ipairs(list or {}) do
        map[entry.id] = entry
    end
    return map
end

-- a barber's version of the saved look: only hair, eyes and the barber overlays come from what was sent
local function barberLook(saved, sent)
    local merged = copy(saved)
    merged.hair = copy(sent.hair)
    merged.eyes = sent.eyes
    local mine, theirs = overlayMap(saved.overlays), overlayMap(sent.overlays)
    merged.overlays = {}
    for _, def in ipairs(C.overlays) do
        local entry = barberSet[def.id] and theirs[def.id] or (not barberSet[def.id] and mine[def.id]) or nil
        if entry then
            table.insert(merged.overlays, copy(entry))
        end
    end
    return merged
end

local function sameLook(a, b)
    if a.eyes ~= b.eyes then return false end
    if a.hair.style ~= b.hair.style or a.hair.color ~= b.hair.color or a.hair.highlight ~= b.hair.highlight then
        return false
    end
    local one, two = overlayMap(a.overlays), overlayMap(b.overlays)
    for _, def in ipairs(C.overlays) do
        local x, y = one[def.id], two[def.id]
        if (x == nil) ~= (y == nil) then return false end
        if x and (x.style ~= y.style or x.opacity ~= y.opacity or x.color ~= y.color) then return false end
    end
    return true
end

FrameOS.onAsk('buyBarber', function(source, index, look)
    local d = FrameOS.getPlayer(source)
    if not d.character then
        return no('Make your character first')
    end
    local barber = spotAt(source, Config.barbers, index, 5.0)
    if not barber then
        return no('You are not at a barber')
    end
    local merged = barberLook(d.character.look, FrameOS.cleanLook(look))
    if sameLook(merged, d.character.look) then
        return no('Nothing changed')
    end
    local price = barber.price or Config.barberPrice
    if not FrameOS.takeCash(source, price, 'barber ' .. math.floor(index)) then
        return no('You need ' .. price .. ' in cash')
    end
    d.character.look = merged
    FrameOS.markDirty(source)
    FrameOS.log('clothes', source, 'new hair and face details at the barber for ' .. price)
    FrameOS.push(source)
    return { ok = true, price = price }
end, { every = 500 })

-- ---------------------------------------------------------------- wardrobes

local function wardrobeHere(source, kind, ref)
    if kind == 'spot' then
        return spotAt(source, Config.wardrobes, ref, 5.0) ~= nil
    elseif kind == 'safehouse' and type(ref) == 'string' then
        local house = Config.safehouses[ref]
        if house then
            return near(source, house.x, house.y, house.z, 8.0)
        end
        -- a safehouse you built in game only exists on your computer: admins in test mode only
        return Config.testCommands and FrameOS.isAdmin(source)
    end
    return false
end

local function cleanWardrobeName(text, slot)
    if type(text) == 'string' then
        text = text:gsub('^%s+', ''):gsub('%s+$', '')
        if #text >= 1 and #text <= 20 and text:match("^[%w][%w '%-%.]*$") then
            return text
        end
    end
    return 'Outfit ' .. slot
end

local function slotIndex(d, slot)
    for i, entry in ipairs(d.wardrobe) do
        if entry.slot == slot then
            return i
        end
    end
    return nil
end

FrameOS.onAsk('wardrobe', function(source, kind, ref, action, slot, arg)
    local d = FrameOS.getPlayer(source)
    if not d.character then
        return no('Make your character first')
    end
    if not wardrobeHere(source, kind, ref) then
        return no('You are not at a wardrobe')
    end
    slot = math.floor(tonumber(slot) or 0)
    if slot < 1 or slot > Config.wardrobeSlots then
        return no('Bad slot')
    end
    local at = slotIndex(d, slot)

    if action == 'save' then
        local outfit = FrameOS.cleanOutfit(type(arg) == 'table' and arg.outfit)
        local entry = { slot = slot, name = cleanWardrobeName(type(arg) == 'table' and arg.name, slot), outfit = outfit }
        if at then
            d.wardrobe[at] = entry
        else
            table.insert(d.wardrobe, entry)
        end
    elseif not at then
        return no('That slot is empty')
    elseif action == 'wear' then
        d.character.outfit = copy(d.wardrobe[at].outfit)
    elseif action == 'rename' then
        d.wardrobe[at].name = cleanWardrobeName(arg, slot)
    elseif action == 'delete' then
        table.remove(d.wardrobe, at)
    else
        return no('Bad request')
    end
    FrameOS.markDirty(source)
    FrameOS.log('clothes', source, 'wardrobe ' .. action .. ' slot ' .. slot)
    FrameOS.push(source)
    return { ok = true }
end, { every = 400 })
