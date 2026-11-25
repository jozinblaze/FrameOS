-- basics: the old-school sandbox essentials.
-- when you spawn in you get full health, armor and the weapons you carry.
-- trunk weapons are not given here, they come from a car's trunk (trunk.lua).
-- changing ped later keeps your health, armor and weapons (see outfit.lua).

local godMode = false

local function giveLoadout()
    local ped = PlayerPedId()
    for _, gun in ipairs(Config.loadout) do
        -- heavy weapons stay in the trunk
        if not (gun.trunk and Config.trunkWeapons) then
            GiveWeaponToPed(ped, joaat(gun.name), gun.ammo, false, false)
        end
    end
end

FrameOS.testCommand('heal', 'full health', function()
    SetEntityHealth(PlayerPedId(), GetEntityMaxHealth(PlayerPedId()))
    FrameOS.notify('Healed')
end)

FrameOS.testCommand('armor', 'full armor', function()
    SetPedArmour(PlayerPedId(), 100)
    FrameOS.notify('Armor full')
end)

FrameOS.testCommand('fix', 'repairs and cleans the car you are in', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        FrameOS.notify('Get in a car first')
        return
    end
    SetVehicleFixed(vehicle)
    SetVehicleDeformationFixed(vehicle)
    SetVehicleDirtLevel(vehicle, 0.0)
    FrameOS.notify('Car fixed')
end)

FrameOS.testCommand('guns', 'gives the weapons you carry (not the trunk ones)', function()
    giveLoadout()
    FrameOS.notify('Loadout given')
end)

FrameOS.testCommand('wanted', 'sets your wanted level, example: /wanted 3', function(source, args)
    local level = tonumber(args[1])
    if not level or level < 0 or level > 5 then
        FrameOS.notify('Usage: /wanted <0-5>')
        return
    end
    SetPlayerWantedLevel(PlayerId(), level, false)
    SetPlayerWantedLevelNow(PlayerId(), false)
end)

FrameOS.testCommand('cops', 'police attention, /cops off or /cops on', function(source, args)
    if args[1] == 'off' then
        ClearPlayerWantedLevel(PlayerId())
        SetMaxWantedLevel(0)       -- 0 means you can't get a wanted level
        FrameOS.notify('Cops off')
    elseif args[1] == 'on' then
        SetMaxWantedLevel(5)
        FrameOS.notify('Cops on')
    else
        FrameOS.notify('Usage: /cops off  or  /cops on')
    end
end)

FrameOS.testCommand('god', 'toggles invincibility', function()
    godMode = not godMode
    SetPlayerInvincible(PlayerId(), godMode)
    if godMode then
        FrameOS.notify('God mode on')
    else
        FrameOS.notify('God mode off')
    end
end)

-- on spawn: full health, armor and the starter guns
FrameOS.onSpawn(function()
    local ped = PlayerPedId()
    SetEntityHealth(ped, GetEntityMaxHealth(ped))
    SetPedArmour(ped, 100)
    giveLoadout()
    if godMode then
        SetPlayerInvincible(PlayerId(), true)
    end
end)
