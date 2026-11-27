-- Standalone multiplayer interactions: AFK heartbeats, tackles, vehicle push,
-- and configurable elevator/teleport groups. No framework or library exports.

RegisterNetEvent('frameos:standaloneNotify', function(message)
    FrameOS.notify(message)
end)

-- The server only accepts a heartbeat for the sending player. Keep the sampled
-- controls limited to real gameplay inputs, then report at most every 15 seconds.
if Config.afk.enabled then
    CreateThread(function()
        local controlsToWatch = { 1, 2, 21, 22, 24, 25, 30, 31, 32, 33, 34, 35,
            36, 37, 38, 44, 45, 47, 51, 71, 72, 73, 75, 76, 140, 141, 142,
            167, 172, 173, 174, 175, 191, 245, 249 }
        local lastSent = 0
        while true do
            Wait(500)
            local active = false
            for _, control in ipairs(controlsToWatch) do
                if IsControlPressed(0, control) or IsDisabledControlPressed(0, control) then
                    active = true
                    break
                end
            end
            local now = GetGameTimer()
            if active and now - lastSent >= (Config.afk.checkEvery or 15) * 1000 then
                lastSent = now
                TriggerServerEvent('frameos:activity')
            end
        end
    end)
end

-- Tackle requests are checked by the server for distance, speed, vehicle state,
-- and cooldown before the target receives the ragdoll event.
local function tryTackle()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped)
        or (not IsPedRunning(ped) and not IsPedSprinting(ped)) then return end
    local origin = GetEntityCoords(ped)
    local closest, closestDistance = nil, 1.6
    for _, player in ipairs(GetActivePlayers()) do
        if player ~= PlayerId() then
            local targetPed = GetPlayerPed(player)
            if targetPed ~= 0 and not IsPedInAnyVehicle(targetPed, true) then
                local distance = #(origin - GetEntityCoords(targetPed))
                if distance < closestDistance then
                    closest, closestDistance = player, distance
                end
            end
        end
    end
    if not closest then return end

    local dict = 'swimming@first_person@diving'
    RequestAnimDict(dict)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited < 1000 do Wait(10); waited = waited + 10 end
    TriggerServerEvent('frameos:tryTackle', GetPlayerServerId(closest))
    if HasAnimDictLoaded(dict) then
        TaskPlayAnim(ped, dict, 'dive_run_fwd_-45_loop', 3.0, 3.0, 250, 49, 0.0, false, false, false)
        Wait(250)
        ClearPedTasks(ped)
        SetPedToRagdoll(ped, 250, 250, 0, false, false, false)
        RemoveAnimDict(dict)
    end
end

RegisterCommand('frameos_tackle', tryTackle, false)
RegisterKeyMapping('frameos_tackle', 'Tackle a nearby player while running', 'keyboard', Config.utilityControls.tackle)
RegisterNetEvent('frameos:tackled', function()
    SetPedToRagdoll(PlayerPedId(), 3500, 3500, 0, false, false, false)
end)

-- The vehicle owner applies the replicated push command. Server validation keeps
-- the request limited to nearby, empty, disabled vehicles.
local pushState = {}
local pushThread = {}
local function serverPlayerId()
    return GetPlayerServerId(PlayerId())
end

local function runVehicleControl(vehicle)
    if pushThread[vehicle] then return end
    pushThread[vehicle] = true
    CreateThread(function()
        local owner = serverPlayerId()
        while DoesEntityExist(vehicle) and pushState[vehicle] do
            if NetworkGetEntityOwner(vehicle) == PlayerId() or NetworkGetEntityOwner(vehicle) == owner then
                local direction = pushState[vehicle]
                local ped = PlayerPedId()
                if direction == 'left' then TaskVehicleTempAction(ped, vehicle, 11, 1)
                elseif direction == 'right' then TaskVehicleTempAction(ped, vehicle, 10, 1) end
                SetVehicleForwardSpeed(vehicle, (direction == 'front') and -1.0 or 1.0)
                if HasEntityCollidedWithAnything(vehicle) then SetVehicleOnGroundProperly(vehicle) end
            end
            Wait(0)
        end
        pushThread[vehicle] = nil
    end)
end

AddStateBagChangeHandler('frameosPushDirection', nil, function(bagName, _, direction)
    local vehicle = GetEntityFromStateBagName(bagName)
    if vehicle == 0 then return end
    pushState[vehicle] = direction
    if direction then runVehicleControl(vehicle) end
end)

local pushing = nil
local pushHeld = false
local pushDirection = nil
local function nearestPushable()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return nil end
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, Config.vehicleUtilities.pushDistance, 0, 71)
    if vehicle == 0 then return nil end
    if #(coords - GetEntityCoords(vehicle)) > Config.vehicleUtilities.pushDistance then return nil end
    if GetVehicleEngineHealth(vehicle) > Config.vehicleUtilities.pushEngineHealth
        or not IsVehicleSeatFree(vehicle, -1) then return nil end
    for _, class in ipairs(Config.vehicleUtilities.pushBlacklistedClasses) do
        if GetVehicleClass(vehicle) == class then return nil end
    end
    return vehicle
end

local function beginPush()
    pushHeld = true
    if pushing then return end
    local ped = PlayerPedId()
    local vehicle = nearestPushable()
    if not vehicle then return end
    local netId = VehToNet(vehicle)
    if netId == 0 then return end
    local coords = GetEntityCoords(ped)
    local vehicleCoords = GetEntityCoords(vehicle)
    local forward = GetEntityForwardVector(vehicle)
    local isFront = #(vehicleCoords - coords + forward) < #(vehicleCoords - coords - forward)
    pushDirection = isFront and 'front' or 'back'
    pushing = vehicle
    local dict = 'missfinale_c2ig_11'
    RequestAnimDict(dict)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited < 1500 do Wait(10); waited = waited + 10 end
    if not HasAnimDictLoaded(dict) then pushing = nil; return end

    local bone = GetPedBoneIndex(ped, 6286)
    local minDim, maxDim = GetModelDimensions(GetEntityModel(vehicle))
    local y = isFront and (minDim.y * -1 + 0.1) or (minDim.y - 0.3)
    AttachEntityToEntity(ped, vehicle, bone, 0.0, y, maxDim.z + 1.0, 0.0, 0.0, isFront and 180.0 or 0.0,
        false, false, false, true, 0, true)
    TaskPlayAnim(ped, dict, 'pushcar_offcliff_m', 2.0, -8.0, -1, 35, 0.0, false, false, false)
    TriggerServerEvent('frameos:vehiclePush', { netId = netId, direction = pushDirection })

    CreateThread(function()
        local lastDirection = pushDirection
        while pushHeld and pushing == vehicle and not IsEntityDead(ped) and not IsPedInAnyVehicle(ped, false) do
            Wait(0)
            DisableControlAction(0, 34, true)
            DisableControlAction(0, 35, true)
            if IsDisabledControlPressed(0, 34) then pushDirection = 'left'
            elseif IsDisabledControlPressed(0, 35) then pushDirection = 'right'
            elseif lastDirection == 'left' or lastDirection == 'right' then pushDirection = isFront and 'front' or 'back' end
            if pushDirection ~= lastDirection then
                lastDirection = pushDirection
                TriggerServerEvent('frameos:vehiclePush', { netId = netId, direction = pushDirection })
            end
        end
        DetachEntity(ped, false, false)
        StopAnimTask(ped, dict, 'pushcar_offcliff_m', 2.0)
        RemoveAnimDict(dict)
        TriggerServerEvent('frameos:vehiclePush', { netId = netId })
        pushing = nil
        pushDirection = nil
    end)
end

RegisterCommand('+frameos_pushvehicle', beginPush, false)
RegisterCommand('-frameos_pushvehicle', function() pushHeld = false end, false)
RegisterKeyMapping('+frameos_pushvehicle', 'Hold to push a nearby disabled vehicle', 'keyboard', Config.utilityControls.pushVehicle)

-- Teleport groups are configured in data/standalone.lua. A group is a list of
-- stops; users interact in a small marker and choose from that group's stops.
local teleportGroups = Config.teleportGroups or {}
local menuOpen = false
local function destinationPosition(destination)
    local z = destination.z
    if destination.useGround ~= false then
        local found, ground = GetGroundZFor_3dCoord(destination.x, destination.y, destination.z + 1.0, false)
        if found and math.abs(ground - destination.z) < 5.0 then z = ground end
    end
    return z
end

local function teleportMenu(group)
    if menuOpen or #group.stops < 2 then return end
    menuOpen = true
    local index = 1
    local ped = PlayerPedId()
    while menuOpen do
        Wait(0)
        FrameOS.drawText(group.label or 'Elevator', 0.5, 0.25, 0.65, true)
        for i, stop in ipairs(group.stops) do
            local marker = (i == index) and '> ' or '  '
            FrameOS.drawText(marker .. (stop.label or ('Floor ' .. i)), 0.5, 0.33 + (i - 1) * 0.05, 0.5, true,
                i == index and { 255, 220, 80 } or nil)
        end
        FrameOS.drawText('Up / Down choose     Enter travel     Backspace close', 0.5, 0.75, 0.4, true)
        if IsControlJustPressed(0, 172) then index = index > 1 and index - 1 or #group.stops
        elseif IsControlJustPressed(0, 173) then index = index % #group.stops + 1
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then
            local stop = group.stops[index]
            local vehicle = GetVehiclePedIsIn(ped, false)
            local entity = (stop.allowVehicle and vehicle ~= 0) and vehicle or ped
            local z = destinationPosition(stop)
            if entity == ped then
                FrameOS.placePed(stop.x, stop.y, z, stop.heading)
            else
                RequestCollisionAtCoord(stop.x, stop.y, z)
                SetEntityCoords(entity, stop.x, stop.y, z, false, false, false, false)
                if stop.heading then SetEntityHeading(entity, stop.heading) end
                SetVehicleOnGroundProperly(vehicle)
            end
            menuOpen = false
        elseif IsControlJustPressed(0, 177) then menuOpen = false end
    end
end

CreateThread(function()
    while true do
        local wait = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for _, group in ipairs(teleportGroups) do
            for _, stop in ipairs(group.stops or {}) do
                local distance = #(coords - vector3(stop.x, stop.y, stop.z))
                if distance < 25.0 then
                    wait = 0
                    DrawMarker(1, stop.x, stop.y, stop.z - 1.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.0, 1.0, 0.4, 80, 160, 255, 140, false, false, 2, false, nil, nil, false)
                    if distance < 1.5 and not menuOpen then
                        FrameOS.help('Press ~INPUT_CONTEXT~ to use ' .. (group.label or 'the elevator'))
                        if IsControlJustPressed(0, 38) then teleportMenu(group) end
                    end
                end
            end
        end
        Wait(wait)
    end
end)
