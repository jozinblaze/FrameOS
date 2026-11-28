-- safehouses: a glowing circle you can rest at (press E).
-- resting fills health and armor and clears your wanted level.
-- make one with /setsafehouse and teleport back with /home.

-- ones you made (name -> x, y, z)
local mine = FrameOS.load('safehouses', {})

-- the full list in use: config ones plus yours
local houses = {}
local blips = {}    -- map icons we made, so we can redo them

local function rebuild()
    houses = {}
    for name, h in pairs(Config.safehouses) do
        houses[name] = h
    end
    for name, h in pairs(mine) do
        houses[name] = h
    end

    -- redo the map icons (40 is the house icon, 5 is yellow)
    FrameOS.removeBlips(blips)
    blips = {}
    for name, h in pairs(houses) do
        local blip = FrameOS.addBlip(h.x, h.y, h.z, 40, 5, 'Safehouse: ' .. name)
        if blip then
            table.insert(blips, blip)
        end
    end
end

rebuild()

-- the actual resting
local function rest()
    -- fade out
    DoScreenFadeOut(600)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    ClearPlayerWantedLevel(PlayerId())

    -- resting is a save point
    FrameOS.saveState()

    Wait(400)
    DoScreenFadeIn(600)
    FrameOS.notify('Rested and saved')
end

-- moves you (and your car if you're in one)
local function goTo(spot)
    local ped = PlayerPedId()
    local thing = ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        thing = vehicle
    end
    SetEntityCoords(thing, spot.x, spot.y, spot.z, false, false, false, false)
end

CreateThread(function()
    while true do
        -- nothing nearby: check only twice a second. something near: every frame.
        local sleep = 500
        local coords = GetEntityCoords(PlayerPedId())

        for name, h in pairs(houses) do
            local dist = #(coords - vector3(h.x, h.y, h.z))
            if dist < 30.0 then
                sleep = 0
                -- pink circle on the ground
                DrawMarker(1, h.x, h.y, h.z - 1.0,
                    0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                    1.5, 1.5, 0.6,
                    255, 120, 200, 150,
                    false, false, 2, false, nil, nil, false)

                if dist < 1.5 then
                    -- ~INPUT_CONTEXT~ turns into the E key icon
                    FrameOS.help('Press ~INPUT_CONTEXT~ to rest at ' .. name .. ', ~INPUT_DETONATE~ for the stash, H for the wardrobe')
                    if IsControlJustPressed(0, 38) then   -- 38 is the E key
                        rest()
                    elseif IsControlJustPressed(0, 47) and FrameOS.openStorage then   -- 47 is the G key
                        FrameOS.openStorage('stash', name)
                    elseif IsControlJustPressed(0, 74) and FrameOS.openSafehouseWardrobe then   -- 74 is the H key
                        FrameOS.openSafehouseWardrobe(name)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

FrameOS.testCommand('setsafehouse', 'makes a safehouse where you stand, example: /setsafehouse beach', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /setsafehouse <name>')
        return
    end
    local name = string.lower(args[1])
    local coords = GetEntityCoords(PlayerPedId())
    mine[name] = { x = coords.x, y = coords.y, z = coords.z }
    FrameOS.save('safehouses', mine)
    rebuild()
    FrameOS.notify('Safehouse saved: ' .. name)
end)

FrameOS.testCommand('delsafehouse', 'removes a safehouse you made', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /delsafehouse <name>')
        return
    end
    local name = string.lower(args[1])
    if mine[name] then
        mine[name] = nil
        FrameOS.save('safehouses', mine)
        rebuild()
        FrameOS.notify('Removed safehouse: ' .. name)
    else
        FrameOS.notify('You have no safehouse called ' .. name)
    end
end)

FrameOS.testCommand('safehouses', 'lists every safehouse', function()
    local names = {}
    for name, _ in pairs(houses) do
        table.insert(names, name)
    end
    if #names == 0 then
        FrameOS.notify('No safehouses yet. Use /setsafehouse <name>')
    else
        FrameOS.notify('Safehouses: ' .. table.concat(names, ', '))
    end
end)

FrameOS.testCommand('home', 'teleports to a safehouse, example: /home beach (no name = any one)', function(source, args)
    if args[1] then
        local house = houses[string.lower(args[1])]
        if house then
            goTo(house)
        else
            FrameOS.notify('No safehouse called ' .. args[1])
        end
        return
    end

    -- no name given: go to the first one we find
    for _, house in pairs(houses) do
        goTo(house)
        return
    end
    FrameOS.notify('No safehouses yet. Use /setsafehouse <name>')
end)

FrameOS.addExport(function()
    local lines = { '-- safehouses' }
    for name, h in pairs(mine) do
        table.insert(lines, string.format("Config.safehouses['%s'] = { x = %.2f, y = %.2f, z = %.2f }", name, h.x, h.y, h.z))
    end
    return lines
end)
