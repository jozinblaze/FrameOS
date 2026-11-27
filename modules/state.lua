-- state: remembers who you were, where you were and what you carried,
-- so loading in puts you right back. no database, it's saved on your own computer.
-- /savestate    saves right now
-- /resetstate   forgets it all (next spawn uses the defaults again)
--
-- saved: ped and clothes, health, armor, carried weapons with ammo, position.
-- not saved here: cash, trunk, spots, outfits and the rest, they save themselves.
-- trunk weapons are left out on purpose, they belong in the trunk.

-- we don't save until you've fully spawned in, or we'd save a half-loaded ped
local spawned = false

-- the last place you stood on the ground. if you're falling, flying or
-- parachuting when the save runs, this is saved instead of a spot in mid-air.
local ground = nil

local function inAir()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    local thing = ped
    if vehicle ~= 0 then
        thing = vehicle
    end
    return IsEntityInAir(thing) or IsPedFalling(ped) or GetPedParachuteState(ped) >= 0
end

local function saveNow()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    if not ground or not inAir() then
        ground = coords
    end
    coords = ground
    local snap = FrameOS.snapshot(true)   -- true = leave out trunk weapons

    FrameOS.save('state', {
        outfit = FrameOS.readOutfit(),
        health = snap.health,
        armor = snap.armor,
        weapons = snap.weapons,
        x = coords.x,
        y = coords.y,
        z = coords.z,
    })
end

-- other modules (like resting at a safehouse) can save right now with this
function FrameOS.saveState()
    if spawned and not IsEntityDead(PlayerPedId()) then
        saveNow()
    end
end

-- save on a timer
CreateThread(function()
    while true do
        Wait(Config.saveEvery)
        if spawned and not IsEntityDead(PlayerPedId()) then
            saveNow()
        end
    end
end)

FrameOS.testCommand('savestate', 'saves your ped, health, weapons and position right now', function()
    spawned = true
    saveNow()
    FrameOS.notify('State saved')
end)

FrameOS.testCommand('resetstate', 'forgets your saved state', function()
    FrameOS.forget('state')
    FrameOS.notify('State forgotten')
end)

-- on spawn: put everything back. this runs last, after the defaults,
-- so a saved state wins over the "main" outfit and the "spawn" spot.
FrameOS.onSpawn(function()
    local saved = FrameOS.load('state', nil)
    if saved then
        -- ped and clothes first (this also changes the model if needed)
        -- with a character, the server's look was already put on (modules/character.lua)
        if saved.outfit and not FrameOS.data.character then
            FrameOS.wearOutfit(saved.outfit)
        end

        -- waits for the ground to load first, so you don't fall through the map
        FrameOS.placePed(saved.x, saved.y, saved.z)
        FrameOS.restore(saved)
        ground = vector3(saved.x, saved.y, saved.z)
    end
    spawned = true
end)
