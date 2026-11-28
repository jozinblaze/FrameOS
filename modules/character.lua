-- character: puts your saved character on you. the server keeps it (d.character, see
-- server/character.lua), this reads it from FrameOS.data.character and applies it to your ped.
-- the creator menu that makes a character is in modules/creator.lua.
--
--   FrameOS.applyCharacter(c)        becomes the freemode ped of that sex and puts the look and outfit on
--   FrameOS.applyLook(ped, look)     face, skin, hair and eyes only (the creator uses this live)
--   FrameOS.applyOutfit(ped, outfit) clothes and props only
--   FrameOS.readOutfitParts(ped)     what the ped wears now, as { parts = {...}, props = {...} }
--
-- applying a look always checks the numbers against what the game really has, so a number that is
-- too big becomes the biggest one that exists instead of an invisible head or a missing shirt.

local C = Config.character

-- a number kept between two others
local function clamp(n, low, high)
    return math.max(low, math.min(high, n))
end

-- the top (11) is put on first, then the undershirt (8), then the arms (3), then everything else.
-- the game can change the arms and undershirt by itself when a top goes on, so the arms must come
-- after the top, or they snap back to default (this was the 1.10.0 "top, arms, undershirt reverted" bug).
local partOrder = { [11] = 1, [8] = 2, [3] = 3 }

local function inOrder(parts)
    local list = {}
    for i, part in ipairs(parts or {}) do
        list[i] = part
    end
    table.sort(list, function(a, b)
        local x, y = partOrder[a.id] or 9, partOrder[b.id] or 9
        if x ~= y then return x < y end
        return a.id < b.id
    end)
    return list
end

function FrameOS.applyOutfit(ped, outfit)
    for _, part in ipairs(inOrder(outfit.parts)) do
        local count = GetNumberOfPedDrawableVariations(ped, part.id)
        if count > 0 then
            local drawable = clamp(part.drawable, 0, count - 1)
            local textures = GetNumberOfPedTextureVariations(ped, part.id, drawable)
            SetPedComponentVariation(ped, part.id, drawable, clamp(part.texture or 0, 0, math.max(0, textures - 1)), 0)
        end
    end
    for _, prop in ipairs(outfit.props or {}) do
        if prop.drawable < 0 then
            ClearPedProp(ped, prop.id)
        else
            local count = GetNumberOfPedPropDrawableVariations(ped, prop.id)
            if count > 0 then
                local drawable = clamp(prop.drawable, 0, count - 1)
                local textures = GetNumberOfPedPropTextureVariations(ped, prop.id, drawable)
                SetPedPropIndex(ped, prop.id, drawable, clamp(prop.texture or 0, 0, math.max(0, textures - 1)), true)
            end
        end
    end
end

function FrameOS.readOutfitParts(ped)
    local outfit = { parts = {}, props = {} }
    for _, id in ipairs(C.outfitParts) do
        table.insert(outfit.parts, { id = id, drawable = GetPedDrawableVariation(ped, id), texture = GetPedTextureVariation(ped, id) })
    end
    for _, id in ipairs(C.outfitProps) do
        table.insert(outfit.props, { id = id, drawable = GetPedPropIndex(ped, id), texture = GetPedPropTextureIndex(ped, id) })
    end
    return outfit
end

-- look.overlays can be a list (as saved) or a table keyed by overlay id (as the creator edits it)
local function overlayFor(overlays, id)
    -- an entry in the table form has no id field of its own (a list entry does)
    if overlays[id] and overlays[id].id == nil then
        return overlays[id]
    end
    for _, entry in ipairs(overlays) do
        if entry.id == id then
            return entry
        end
    end
    return nil
end

function FrameOS.applyLook(ped, look)
    -- the two parents and how much of each you take after (0 = all mother, 1 = all father)
    SetPedHeadBlendData(ped, look.mother, look.father, 0, look.mother, look.father, 0,
        look.shapeMix + 0.0, look.skinMix + 0.0, 0.0, false)

    for i = 1, #C.features do
        SetPedFaceFeature(ped, i - 1, (look.features[i] or 0) + 0.0)
    end

    for _, def in ipairs(C.overlays) do
        local overlay = overlayFor(look.overlays or {}, def.id)
        if overlay and overlay.style and overlay.style >= 0 then
            SetPedHeadOverlay(ped, def.id, overlay.style, (overlay.opacity or 1.0) + 0.0)
            if def.color then
                SetPedHeadOverlayColor(ped, def.id, def.color, overlay.color or 0, overlay.color or 0)
            end
        else
            SetPedHeadOverlay(ped, def.id, 255, 0.0)   -- 255 means off
        end
    end

    local hairCount = GetNumberOfPedDrawableVariations(ped, 2)
    SetPedComponentVariation(ped, 2, clamp(look.hair.style, 0, math.max(0, hairCount - 1)), 0, 0)
    SetPedHairColor(ped, look.hair.color, look.hair.highlight)
    SetPedEyeColor(ped, look.eyes)
end

-- turns you into the character. returns true if it worked.
function FrameOS.applyCharacter(c)
    local want = joaat(C.models[c.sex])
    if GetEntityModel(PlayerPedId()) ~= want then
        if not FrameOS.setModel(want) then
            FrameOS.notify('Could not load your character')
            return false
        end
    end
    local ped = PlayerPedId()
    SetPedDefaultComponentVariation(ped)    -- a clean start, so nothing from the last ped is left
    FrameOS.applyOutfit(ped, c.outfit)
    FrameOS.applyLook(ped, c.look)
    return true
end

-- at spawn: wait for the server's data, then put your character on you, or open the creator
-- if you do not have one yet. this runs before state.lua restores your position and weapons.
FrameOS.onSpawn(function()
    local waited = 0
    while not FrameOS.loaded and waited < 15000 do
        Wait(100)
        waited = waited + 100
    end
    if not FrameOS.loaded then
        return   -- the server never answered, keep whatever ped the game gave us
    end
    if FrameOS.data.character then
        FrameOS.applyCharacter(FrameOS.data.character)
    else
        FrameOS.openCreator(false)
    end
end)

FrameOS.testCommand('saveclothes', 'saves what you are wearing as your character outfit (admins)', function()
    CreateThread(function()
        if FrameOS.request('saveClothes', FrameOS.readOutfitParts(PlayerPedId())) then
            FrameOS.notify('Outfit saved to your character')
        end
    end)
end)

FrameOS.command('whoami', 'shows your character name', function()
    local c = FrameOS.data.character
    if c then
        FrameOS.notify(c.name.first .. ' ' .. c.name.last)
    else
        FrameOS.notify('You have no character yet')
    end
end)
