-- trunk: heavy weapons (trunk = true in the config) live in a car's trunk.
-- walk up to the back of any car and press E to open the trunk and take them.
-- walk away, get in a car, or press E again and they go back in the trunk.
-- if you ever end up holding one without taking it from a trunk, it's
-- pulled off you within a quarter of a second.
-- /trunkdebug prints what the game says you're carrying (F8 console).

-- what's stored in the trunk: weapon name -> ammo
if not Config.trunkWeapons then
    return   -- switched off in config.lua, nothing below runs
end

local stored = FrameOS.load('trunk', nil)
if not stored then
    stored = {}
    for _, gun in ipairs(Config.loadout) do
        if gun.trunk then
            stored[gun.name] = gun.ammo
        end
    end
end

local armed = false       -- are you carrying the trunk weapons right now?
local openVehicle = nil   -- the car whose trunk is open

-- where the trunk is on a car
local function trunkPosition(vehicle)
    local bone = GetEntityBoneIndexByName(vehicle, 'boot')
    if bone ~= -1 then
        return GetWorldPositionOfEntityBone(vehicle, bone)
    end
    -- no boot bone on this car: use the middle of the back end
    local min, max = GetModelDimensions(GetEntityModel(vehicle))
    return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, min.y, 0.0)
end

local function takeWeapons(vehicle)
    local ped = PlayerPedId()
    SetVehicleDoorOpen(vehicle, 5, false, false)   -- door 5 is the trunk
    for name, ammo in pairs(stored) do
        GiveWeaponToPed(ped, joaat(name), ammo, false, false)
    end
    armed = true
    openVehicle = vehicle
    FrameOS.notify('Took weapons from the trunk')
end

-- true if you still carry any of the trunk weapons
local function carryingTrunkWeapons()
    local ped = PlayerPedId()
    for name, _ in pairs(stored) do
        if HasPedGotWeapon(ped, joaat(name), false) then
            return true
        end
    end
    return false
end

-- takes the trunk weapons off you completely and remembers the ammo left
local function removeTrunkWeapons()
    local ped = PlayerPedId()

    -- remember how much ammo was left
    for name, _ in pairs(stored) do
        local hash = joaat(name)
        if HasPedGotWeapon(ped, hash, false) then
            stored[name] = GetAmmoInPedWeapon(ped, hash)
        end
    end

    -- put away whatever is in your hands, one frame later nothing is equipped
    SetCurrentPedWeapon(ped, joaat('WEAPON_UNARMED'), true)
    Wait(0)

    -- first try: take each trunk weapon off on its own, ammo first
    for name, _ in pairs(stored) do
        local hash = joaat(name)
        SetPedAmmo(ped, hash, 0)
        RemoveWeaponFromPed(ped, hash)
    end

    -- second try, if the game still says you have one: wipe every weapon and
    -- give back only the ones you carry (not the trunk ones)
    if carryingTrunkWeapons() then
        print('[trunk] weapons were still on you after removing them one by one, wiping all')
        local keep = FrameOS.snapshot(true)
        RemoveAllPedWeapons(ped, true)
        for _, weapon in ipairs(keep.weapons) do
            GiveWeaponToPed(ped, joaat(weapon.name), weapon.ammo, false, false)
        end
    end

    FrameOS.save('trunk', stored)

    if carryingTrunkWeapons() then
        print('[trunk] WARNING: the game still says you carry a trunk weapon')
    else
        print('[trunk] weapons put away')
    end
end

local function stashWeapons()
    removeTrunkWeapons()
    if openVehicle and DoesEntityExist(openVehicle) then
        SetVehicleDoorShut(openVehicle, 5, false)
    end
    armed = false
    openVehicle = nil
end

CreateThread(function()
    while true do
        -- nothing near a trunk: check four times a second. at a trunk: every frame.
        local sleep = 250
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        local inCar = IsPedInAnyVehicle(ped, false)

        -- carrying them: too far from the trunk, or got in a car? put them back
        if armed then
            local tooFar = true
            if openVehicle and DoesEntityExist(openVehicle) then
                tooFar = #(coords - trunkPosition(openVehicle)) > Config.trunkLeaveRange
            end
            if inCar or tooFar then
                stashWeapons()
            end
        elseif carryingTrunkWeapons() then
            -- not carrying them on purpose, so you shouldn't have any of them
            removeTrunkWeapons()
        end

        -- near a trunk on foot: offer to open it (or close it)
        if not inCar then
            local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 8.0, 0, 71)
            if vehicle ~= 0 then
                local dist = #(coords - trunkPosition(vehicle))
                -- if you're already carrying them, only the car you took them from counts
                local usable = (not armed) or vehicle == openVehicle
                if dist < Config.trunkRange and usable then
                    sleep = 0
                    if armed then
                        FrameOS.help('Press ~INPUT_CONTEXT~ to put the weapons back')
                    else
                        FrameOS.help('Press ~INPUT_CONTEXT~ to open the trunk')
                    end
                    if IsControlJustPressed(0, 38) then   -- 38 is the E key
                        if armed then
                            stashWeapons()
                        else
                            takeWeapons(vehicle)
                        end
                    end
                end
            end
        end

        Wait(sleep)
    end
end)

-- prints what the game thinks you're carrying, so we can tell whether a
-- weapon is really on you or only still showing in the wheel.
FrameOS.testCommand('trunkdebug', 'prints which weapons the game says you carry (F8 console)', function()
    local ped = PlayerPedId()
    print('[trunkdebug] carrying trunk weapons on purpose: ' .. tostring(armed))
    for name, ammo in pairs(stored) do
        local hash = joaat(name)
        print(string.format('[trunkdebug] %s  on you: %s  ammo on you: %d  ammo in trunk: %d',
            name, tostring(HasPedGotWeapon(ped, hash, false)), GetAmmoInPedWeapon(ped, hash), ammo))
    end
    for _, name in ipairs(Config.allWeapons) do
        if HasPedGotWeapon(ped, joaat(name), false) then
            print('[trunkdebug] you carry: ' .. name)
        end
    end
    FrameOS.notify('Trunk info printed in the F8 console')
end)

-- after a respawn the game has wiped your weapons, so you're not carrying them
FrameOS.onSpawn(function()
    armed = false
    openVehicle = nil
end)
