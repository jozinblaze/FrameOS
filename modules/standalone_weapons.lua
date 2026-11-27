-- Weapon and pickup rules for FrameOS. Weapon ownership remains controlled by
-- FrameOS inventory; this module only changes local presentation/gameplay rules.

local rules = Config.weaponUtilities
local nextRecoilAt = 0
local recoilHashes = {}
for name, amount in pairs(rules.recoil or {}) do
    recoilHashes[joaat(name)] = amount
end

if rules.disableWorldWeaponPickups then
    CreateThread(function()
        Wait(1000)
        local pickups = {}
        for _, name in ipairs(Config.allWeapons) do
            if name:sub(1, 7) == 'WEAPON_' then pickups['PICKUP_' .. name] = true end
        end
        for _, item in pairs(Items) do
            if item.weapon and item.weapon:sub(1, 7) == 'WEAPON_' then
                pickups['PICKUP_' .. item.weapon] = true
            end
        end
        for pickupName in pairs(pickups) do
            ToggleUsePickupsForPlayer(PlayerId(), joaat(pickupName), false)
        end
    end)
end

CreateThread(function()
    local stun = rules.stunTime or { min = 4000, max = 7000 }
    while true do
        local ped = PlayerPedId()
        if rules.extendStun and IsPedBeingStunned(ped, 0) then
            SetPedMinGroundTimeForStungun(ped, math.random(stun.min, stun.max))
            Wait(0)
        else
            Wait(500)
        end
    end
end)

CreateThread(function()
    while true do
        Wait(0)
        local now = GetGameTimer()
        if rules.disableWeaponWheel then
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 157, true)
            DisableControlAction(0, 158, true)
            DisableControlAction(0, 159, true)
            DisableControlAction(0, 160, true)
            DisableControlAction(0, 161, true)
            DisableControlAction(0, 162, true)
            DisableControlAction(0, 163, true)
        end
        local ped = PlayerPedId()
        local weapon = GetSelectedPedWeapon(ped)
        if rules.disablePistolWhip and IsPedArmed(ped, 6) then
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
        end
        if rules.infiniteUtilityAmmo and IsPedShooting(ped) then
            if weapon == joaat('WEAPON_FIREEXTINGUISHER') or weapon == joaat('WEAPON_PETROLCAN') then
                SetPedInfiniteAmmo(ped, true, weapon)
            end
        end
        if rules.hideReticle and weapon ~= joaat('WEAPON_UNARMED')
            and IsPlayerFreeAiming(PlayerId()) and not IsFirstPersonAimCamActive() then
            HideHudComponentThisFrame(14)
        end
        local recoil = recoilHashes[weapon]
        if recoil and recoil > 0 and IsPedShooting(ped) and not IsPedDoingDriveby(ped)
            and now >= (nextRecoilAt or 0) then
            local pitch = GetGameplayCamRelativePitch()
            SetGameplayCamRelativePitch(pitch + recoil, 0.2)
            nextRecoilAt = now + 120
        end
    end
end)
