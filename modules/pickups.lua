-- pickups: floating icons you walk into.
-- health (red), armor (blue), cash (green). they come back after a while.

-- what each kind looks like and does
-- marker 2 is an arrow, 29 is a dollar sign (the game's marker numbers)
local kinds = {
    health = {
        marker = 2, r = 255, g = 60, b = 60,
        give = function()
            local ped = PlayerPedId()
            SetEntityHealth(ped, GetEntityMaxHealth(ped))
            FrameOS.notify('Health')
        end,
    },
    armor = {
        marker = 2, r = 60, g = 140, b = 255,
        give = function()
            SetPedArmour(PlayerPedId(), 100)
            FrameOS.notify('Armor')
        end,
    },
    cash = {
        marker = 29, r = 60, g = 220, b = 90,
        give = function()
            FrameOS.addCash(Config.pickupCash)
        end,
    },
}

-- pickups you made yourself (kept between restarts)
local mine = FrameOS.load('pickups', {})

-- the full list in use: config ones plus yours.
-- readyAt is the game time when it can be picked up again (resets on restart)
local all = {}

local function rebuild()
    all = {}
    for _, p in ipairs(Config.pickups) do
        table.insert(all, { kind = p.kind, x = p.x, y = p.y, z = p.z, readyAt = 0 })
    end
    for _, p in ipairs(mine) do
        table.insert(all, { kind = p.kind, x = p.x, y = p.y, z = p.z, readyAt = 0 })
    end
end

rebuild()

CreateThread(function()
    while true do
        -- nothing nearby: check only twice a second. something near: every frame.
        local sleep = 500
        local coords = GetEntityCoords(PlayerPedId())
        local now = GetGameTimer()

        for _, p in ipairs(all) do
            local kind = kinds[p.kind]
            if kind and now >= p.readyAt then
                local dist = #(coords - vector3(p.x, p.y, p.z))
                if dist < 40.0 then
                    sleep = 0
                    DrawMarker(kind.marker, p.x, p.y, p.z + 0.6,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        0.5, 0.5, 0.5,
                        kind.r, kind.g, kind.b, 180,
                        true, false, 2, true, nil, nil, false)

                    if dist < 2.0 then
                        kind.give()
                        p.readyAt = now + Config.pickupRespawn
                        PlaySoundFrontend(-1, 'PICK_UP', 'HUD_FRONTEND_DEFAULT_SOUNDSET', true)
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

FrameOS.testCommand('addpickup', 'puts a pickup where you stand, example: /addpickup health', function(source, args)
    local kind = args[1]
    if not kind or not kinds[kind] then
        FrameOS.notify('Usage: /addpickup health, armor or cash')
        return
    end
    local coords = GetEntityCoords(PlayerPedId())
    table.insert(mine, { kind = kind, x = coords.x, y = coords.y, z = coords.z })
    FrameOS.save('pickups', mine)
    rebuild()
    FrameOS.notify('Added a ' .. kind .. ' pickup')
end)

FrameOS.testCommand('delpickup', 'removes the closest pickup you made (within 3 meters)', function()
    local coords = GetEntityCoords(PlayerPedId())
    local closestIndex = nil
    local closestDist = 3.0

    for index, p in ipairs(mine) do
        local dist = #(coords - vector3(p.x, p.y, p.z))
        if dist < closestDist then
            closestDist = dist
            closestIndex = index
        end
    end

    if closestIndex then
        table.remove(mine, closestIndex)
        FrameOS.save('pickups', mine)
        rebuild()
        FrameOS.notify('Removed pickup')
    else
        FrameOS.notify('None of your pickups within 3 meters')
    end
end)

FrameOS.addExport(function()
    local lines = { '-- pickups' }
    for _, p in ipairs(mine) do
        table.insert(lines, string.format("table.insert(Config.pickups, { kind = '%s', x = %.2f, y = %.2f, z = %.2f })", p.kind, p.x, p.y, p.z))
    end
    return lines
end)
