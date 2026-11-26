-- death: what happens when you die.
-- a short death screen, then you wake up at the nearest hospital with a
-- small bill. you keep your ped, clothes and the weapons you carry.
-- the hospitals, bill, delay and text are all in the config.
-- /respawn is only for getting unstuck if the death screen ever hangs.

local ready = false   -- true once you've spawned in for the first time
local dead = false    -- true while the death screen and respawn are running

-- a map icon for each hospital (61 is the hospital icon, 2 is green)
for _, hospital in ipairs(Config.hospitals) do
    FrameOS.addBlip(hospital.x, hospital.y, hospital.z, 61, 2, hospital.name .. ' Hospital')
end

-- finds the hospital closest to a position
local function nearestHospital(coords)
    local best = nil
    local bestDist = nil
    for _, hospital in ipairs(Config.hospitals) do
        local dist = #(coords - vector3(hospital.x, hospital.y, hospital.z))
        if not bestDist or dist < bestDist then
            best = hospital
            bestDist = dist
        end
    end
    return best
end

local function respawn()
    local ped = PlayerPedId()

    -- your weapons are still on you right now, so remember the ones you carry
    local snap = FrameOS.snapshot(true)

    -- no hospitals in the config? use the spawn spot instead
    local hospital = nearestHospital(GetEntityCoords(ped)) or Config.startSpots['spawn']
    local heading = hospital.h or 0.0

    DoScreenFadeOut(800)
    while not IsScreenFadedOut() do
        Wait(0)
    end

    -- bring you back to life where the hospital is
    NetworkResurrectLocalPlayer(hospital.x, hospital.y, hospital.z, heading, true, false)
    ped = PlayerPedId()
    ClearPedTasksImmediately(ped)
    ClearPedBloodDamage(ped)
    ClearPlayerWantedLevel(PlayerId())   -- the cops lose you when you die
    FreezeEntityPosition(ped, true)   -- hold still until the ground has loaded

    -- wait for the ground to load, then stand on it. groundZ only trusts
    -- ground close to the height in the config, so it can't put you on a roof.
    RequestCollisionAtCoord(hospital.x, hospital.y, hospital.z)
    local waited = 0
    while not HasCollisionLoadedAroundEntity(ped) and waited < 3000 do
        Wait(100)
        waited = waited + 100
    end
    SetEntityCoords(ped, hospital.x, hospital.y, FrameOS.groundZ(hospital.x, hospital.y, hospital.z), false, false, false, false)
    SetEntityHeading(ped, heading)
    FreezeEntityPosition(ped, false)

    -- full health, no armor, and the weapons you carry
    snap.health = GetEntityMaxHealth(ped)
    snap.armor = 0
    FrameOS.restore(snap)

    -- the bill
    -- the server works out the bill (never more than you have) and takes it
    FrameOS.request('hospitalBill')

    AnimpostfxStop('DeathFailOut')
    DoScreenFadeIn(800)
end

-- the death screen, then the respawn
local function handleDeath()
    dead = true
    AnimpostfxPlay('DeathFailOut', 0, true)

    local endTime = GetGameTimer() + Config.respawnDelay
    while GetGameTimer() < endTime do
        Wait(0)
        FrameOS.drawText(Config.deathText, 0.5, 0.42, 1.2, true)
    end

    respawn()
    dead = false
end

CreateThread(function()
    while true do
        Wait(250)
        if ready and not dead and IsEntityDead(PlayerPedId()) then
            handleDeath()
        end
    end
end)

FrameOS.command('respawn', 'wakes you up at the nearest hospital if you are stuck dead', function()
    if ready and not dead and IsEntityDead(PlayerPedId()) then
        handleDeath()
    else
        FrameOS.notify('You are not dead')
    end
end)

-- after your first spawn, we take over from the game's own respawning.
-- (before that, the game still has to spawn you in the first time.)
FrameOS.onSpawn(function()
    pcall(function()
        exports.spawnmanager:setAutoSpawn(false)
    end)
    SetFadeOutAfterDeath(false)
    ready = true
end)
