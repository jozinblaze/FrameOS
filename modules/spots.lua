-- spots: save places and jump back to them.
-- save a spot called "spawn" and you start there every time you join.

-- your own saved spots (name -> x, y, z)
local mySpots = FrameOS.load('spots', {})

-- looks in your spots first, then the starter ones from the config
local function findSpot(name)
    return mySpots[name] or Config.startSpots[name]
end

-- moves you (and your car if you're in one) to a spot
local function goTo(spot)
    local ped = PlayerPedId()
    local thing = ped
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle ~= 0 then
        thing = vehicle
    end
    SetEntityCoords(thing, spot.x, spot.y, spot.z, false, false, false, false)
end

FrameOS.testCommand('setspot', 'saves where you stand, example: /setspot beach', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /setspot <name>')
        return
    end
    local name = string.lower(args[1])
    local coords = GetEntityCoords(PlayerPedId())
    mySpots[name] = { x = coords.x, y = coords.y, z = coords.z }
    FrameOS.save('spots', mySpots)
    FrameOS.notify('Saved spot: ' .. name)
end)

FrameOS.testCommand('spot', 'teleports to a spot, example: /spot beach', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /spot <name>  (try /spots)')
        return
    end
    local spot = findSpot(string.lower(args[1]))
    if spot then
        goTo(spot)
    else
        FrameOS.notify('No spot called ' .. args[1])
    end
end)

FrameOS.testCommand('spots', 'lists every spot', function()
    local names = {}
    for name, _ in pairs(Config.startSpots) do
        table.insert(names, name)
    end
    for name, _ in pairs(mySpots) do
        table.insert(names, name)
    end
    FrameOS.notify('Spots: ' .. table.concat(names, ', '))
end)

FrameOS.testCommand('delspot', 'removes one of your saved spots', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /delspot <name>')
        return
    end
    local name = string.lower(args[1])
    if mySpots[name] then
        mySpots[name] = nil
        FrameOS.save('spots', mySpots)
        FrameOS.notify('Removed spot: ' .. name)
    else
        FrameOS.notify('You have no saved spot called ' .. name)
    end
end)

-- on spawn: go to your "spawn" spot if you made one
FrameOS.onSpawn(function()
    -- your own "spawn" spot wins, then the preset one from the config
    local spot = mySpots['spawn'] or Config.startSpots['spawn']
    if spot then
        goTo(spot)
    end
end)

FrameOS.addExport(function()
    local lines = { '-- spots' }
    for name, s in pairs(mySpots) do
        table.insert(lines, string.format("Config.startSpots['%s'] = { x = %.2f, y = %.2f, z = %.2f }", name, s.x, s.y, s.z))
    end
    return lines
end)
