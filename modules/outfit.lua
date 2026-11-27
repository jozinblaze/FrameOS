-- outfit: pick your ped, change your clothes, save the look.
-- no clothing menu, everything is a command.
-- save a look called "main" and you load into it every time you join.
-- skip the mp_m_freemode_01 / mp_f_freemode_01 peds for now, they need
-- face setup this module doesn't do.

-- clothing slots: 0 head, 1 mask, 2 hair, 3 torso/arms, 4 legs, 5 bags,
-- 6 shoes, 7 accessories, 8 undershirt, 9 armor, 10 decals, 11 jacket
local partIds = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11 }

-- props (things you put ON): 0 hats, 1 glasses, 2 ear items, 6 watches, 7 bracelets
local propIds = { 0, 1, 2, 6, 7 }

local outfits = FrameOS.load('outfits', {})

-- turns you into a different ped. returns true if it worked
local function setModel(model)
    if not IsModelInCdimage(model) or not IsModelAPed(model) then
        return false
    end

    if not FrameOS.loadModel(model) then
        return false
    end

    -- changing ped wipes health, armor and weapons, so remember them first
    local snap = FrameOS.snapshot()

    SetPlayerModel(PlayerId(), model)
    SetModelAsNoLongerNeeded(model)
    -- start the new ped with its normal clothes
    SetPedDefaultComponentVariation(PlayerPedId())

    -- and give them back
    FrameOS.restore(snap)
    return true
end

-- looks at what you're wearing right now and returns it as a table
local function readOutfit()
    local ped = PlayerPedId()
    local outfit = { model = GetEntityModel(ped), parts = {}, props = {} }

    for _, id in ipairs(partIds) do
        table.insert(outfit.parts, {
            id = id,
            drawable = GetPedDrawableVariation(ped, id),
            texture = GetPedTextureVariation(ped, id),
        })
    end

    for _, id in ipairs(propIds) do
        -- -1 means nothing is worn in that slot
        table.insert(outfit.props, {
            id = id,
            drawable = GetPedPropIndex(ped, id),
            texture = GetPedPropTextureIndex(ped, id),
        })
    end

    return outfit
end

-- puts a saved look on you (changes your ped first if it's a different one)
local function wearOutfit(outfit)
    if outfit.model and outfit.model ~= GetEntityModel(PlayerPedId()) then
        setModel(outfit.model)
    end

    -- grab the ped AFTER the model change, it's a new ped now
    local ped = PlayerPedId()

    for _, part in ipairs(outfit.parts) do
        SetPedComponentVariation(ped, part.id, part.drawable, part.texture, 0)
    end

    for _, prop in ipairs(outfit.props) do
        if prop.drawable == -1 then
            ClearPedProp(ped, prop.id)
        else
            SetPedPropIndex(ped, prop.id, prop.drawable, prop.texture, true)
        end
    end
end

-- other modules (state) need these two
FrameOS.readOutfit = readOutfit
FrameOS.wearOutfit = wearOutfit
FrameOS.setModel = setModel   -- the character module uses this to become a freemode ped

FrameOS.testCommand('ped', 'become a ped, example: /ped a_m_y_beach_01', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /ped <model>')
        return
    end
    if not setModel(joaat(args[1])) then
        FrameOS.notify('No ped called ' .. args[1])
    end
end)

FrameOS.testCommand('clothinfo', 'prints how many options each clothing slot has (F8)', function()
    local ped = PlayerPedId()
    for _, id in ipairs(partIds) do
        -- options start at 0, so the last one is count - 1
        local count = GetNumberOfPedDrawableVariations(ped, id)
        print('slot ' .. id .. ': 0 to ' .. (count - 1))
    end
    for _, id in ipairs(propIds) do
        local count = GetNumberOfPedPropDrawableVariations(ped, id)
        print('prop ' .. id .. ': 0 to ' .. (count - 1))
    end
    FrameOS.notify('Slot info printed in the F8 console')
end)

FrameOS.testCommand('cloth', 'change a slot, example: /cloth 4 2 1 (slot number texture)', function(source, args)
    local slot = tonumber(args[1])
    local number = tonumber(args[2])
    local texture = tonumber(args[3]) or 0
    if not slot or not number then
        FrameOS.notify('Usage: /cloth <slot> <number> [texture]')
        return
    end
    SetPedComponentVariation(PlayerPedId(), slot, number, texture, 0)
end)

FrameOS.testCommand('prop', 'change a prop, example: /prop 0 5 (-1 takes it off)', function(source, args)
    local slot = tonumber(args[1])
    local number = tonumber(args[2])
    local texture = tonumber(args[3]) or 0
    if not slot or not number then
        FrameOS.notify('Usage: /prop <slot> <number> [texture]')
        return
    end
    if number == -1 then
        ClearPedProp(PlayerPedId(), slot)
    else
        SetPedPropIndex(PlayerPedId(), slot, number, texture, true)
    end
end)

FrameOS.testCommand('saveoutfit', 'saves your ped and clothes, example: /saveoutfit main', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /saveoutfit <name>')
        return
    end
    local name = string.lower(args[1])
    outfits[name] = readOutfit()
    FrameOS.save('outfits', outfits)
    FrameOS.notify('Saved outfit: ' .. name)
end)

FrameOS.testCommand('outfit', 'puts a saved look on, example: /outfit main', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /outfit <name>  (try /outfits)')
        return
    end
    local outfit = outfits[string.lower(args[1])]
    if outfit then
        wearOutfit(outfit)
    else
        FrameOS.notify('No outfit called ' .. args[1])
    end
end)

FrameOS.testCommand('outfits', 'lists your saved looks', function()
    local names = {}
    for name, _ in pairs(outfits) do
        table.insert(names, name)
    end
    if #names == 0 then
        FrameOS.notify('No outfits saved yet')
    else
        FrameOS.notify('Outfits: ' .. table.concat(names, ', '))
    end
end)

FrameOS.testCommand('deloutfit', 'removes a saved look', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /deloutfit <name>')
        return
    end
    local name = string.lower(args[1])
    if outfits[name] then
        outfits[name] = nil
        FrameOS.save('outfits', outfits)
        FrameOS.notify('Removed outfit: ' .. name)
    else
        FrameOS.notify('No outfit called ' .. name)
    end
end)

-- on spawn: put on the "main" look if you saved one
FrameOS.onSpawn(function()
    -- once you have a character (modules/character.lua) the server's look is the only look
    if outfits['main'] and not (FrameOS.data and FrameOS.data.character) then
        wearOutfit(outfits['main'])
    end
end)
