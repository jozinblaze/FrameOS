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

local function saveNow()
    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
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
        FrameOS.wearOutfit(saved.outfit)

        SetEntityCoords(PlayerPedId(), saved.x, saved.y, saved.z, false, false, false, false)
        FrameOS.restore(saved)
    end
    spawned = true
end)
