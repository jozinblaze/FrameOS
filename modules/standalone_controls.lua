-- FrameOS movement and vehicle controls. Native FiveM/GTA APIs only.

local controls = Config.utilityControls
local vehicleConfig = Config.vehicleUtilities
local crouched = false
local cruiseSpeed = 0.0
local radioEnabled = true
local classAllowed = {}
for _, class in ipairs(vehicleConfig.cruiseClasses) do classAllowed[class] = true end

local function tell(text)
    FrameOS.notify(text)
end

local function toggleCrouch()
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end
    crouched = not crouched
    if crouched then
        RequestAnimSet('move_Ped_crouched')
        local waited = 0
        while not HasAnimSetLoaded('move_Ped_crouched') and waited < 2000 do
            Wait(10)
            waited = waited + 10
        end
        if HasAnimSetLoaded('move_Ped_crouched') then
            SetPedMovementClipset(ped, 'move_Ped_crouched', 1.0)
            SetPedStrafeClipset(ped, 'move_Ped_crouched_strafing')
            RemoveAnimSet('move_Ped_crouched')
        else
            crouched = false
            tell('Crouch animation could not be loaded')
        end
    else
        ResetPedMovementClipset(ped, 1.0)
        ResetPedWeaponMovementClipset(ped)
        ResetPedStrafeClipset(ped)
    end
end

local function stopCruise(message)
    if cruiseSpeed > 0.0 then
        cruiseSpeed = 0.0
        if message then tell(message) end
    end
end

local function toggleCruise()
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        tell('You need to be driving')
        return
    end
    if cruiseSpeed > 0.0 then
        stopCruise('Cruise control off')
        return
    end
    local class = GetVehicleClass(vehicle)
    local speed = GetEntitySpeed(vehicle)
    if not classAllowed[class] or speed < 5.0 or GetVehicleCurrentGear(vehicle) == 0 then
        tell('This vehicle cannot use cruise control yet')
        return
    end
    cruiseSpeed = speed
    tell('Cruise control set')
end

CreateThread(function()
    while true do
        if cruiseSpeed <= 0.0 then
            Wait(250)
        else
            Wait(0)
            local ped = PlayerPedId()
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
                stopCruise('Cruise control off')
            elseif IsControlPressed(0, 72) or IsControlPressed(0, 63) or IsControlPressed(0, 64) then
                stopCruise('Cruise control cancelled')
            elseif IsVehicleOnAllWheels(vehicle) and GetEntitySpeed(vehicle) < cruiseSpeed then
                SetVehicleForwardSpeed(vehicle, cruiseSpeed)
            end
        end
    end
end)

local function requestControl(entity, timeout)
    if not NetworkGetEntityIsNetworked(entity) then return true end
    local started = GetGameTimer()
    NetworkRequestControlOfEntity(entity)
    while not NetworkHasControlOfEntity(entity) and GetGameTimer() - started < (timeout or 1500) do
        Wait(0)
        NetworkRequestControlOfEntity(entity)
    end
    return NetworkHasControlOfEntity(entity)
end

local flipping = false
local function flipNearestVehicle()
    if flipping then return end
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then return end
    local coords = GetEntityCoords(ped)
    local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, vehicleConfig.flipDistance, 0, 71)
    if vehicle == 0 or #(coords - GetEntityCoords(vehicle)) > vehicleConfig.flipDistance then
        tell('No vehicle close enough to flip')
        return
    end
    if not requestControl(vehicle) then
        tell('Could not take control of that vehicle')
        return
    end

    flipping = true
    local dict = 'mini@repair'
    RequestAnimDict(dict)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited < 2000 do Wait(10); waited = waited + 10 end
    if not HasAnimDictLoaded(dict) then
        flipping = false
        tell('Flip animation could not be loaded')
        return
    end

    TaskPlayAnim(ped, dict, 'fixing_a_ped', 2.0, 2.0, vehicleConfig.flipDuration, 1, 0.0, false, false, false)
    local started = GetGameTimer()
    local startCoords = GetEntityCoords(ped)
    local cancelled = false
    while GetGameTimer() - started < vehicleConfig.flipDuration do
        Wait(0)
        DisableControlAction(0, 24, true)
        DisableControlAction(0, 25, true)
        DisableControlAction(0, 21, true)
        FrameOS.drawText('Flipping vehicle - Backspace to cancel', 0.5, 0.82, 0.42, true)
        if IsControlJustPressed(0, 177) or IsEntityDead(ped)
            or #(GetEntityCoords(ped) - startCoords) > 0.75
            or #(GetEntityCoords(ped) - GetEntityCoords(vehicle)) > vehicleConfig.flipDistance + 1.0 then
            cancelled = true
            break
        end
    end
    ClearPedTasks(ped)
    RemoveAnimDict(dict)
    if not cancelled and DoesEntityExist(vehicle) and requestControl(vehicle) then
        SetVehicleOnGroundProperly(vehicle)
        tell('Vehicle flipped')
    elseif cancelled then
        tell('Flip cancelled')
    end
    flipping = false
end

local function toggleRadio()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then return end
    radioEnabled = not radioEnabled
    SetUserRadioControlEnabled(radioEnabled)
    if not radioEnabled then SetVehRadioStation(vehicle, 'OFF') end
    tell(radioEnabled and 'Vehicle radio controls enabled' or 'Vehicle radio controls disabled')
end

CreateThread(function()
    while true do
        local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
        if vehicle == 0 then
            SetUserRadioControlEnabled(true)
            Wait(1000)
        else
            SetUserRadioControlEnabled(radioEnabled)
            if not radioEnabled then SetVehRadioStation(vehicle, 'OFF') end
            Wait(500)
        end
    end
end)

RegisterCommand('frameos_crouch', toggleCrouch, false)
RegisterKeyMapping('frameos_crouch', 'Toggle crouching', 'keyboard', controls.crouch)
RegisterCommand('frameos_cruise', toggleCruise, false)
RegisterKeyMapping('frameos_cruise', 'Toggle vehicle cruise control', 'keyboard', controls.cruise)
RegisterCommand('frameos_flipvehicle', flipNearestVehicle, false)
RegisterKeyMapping('frameos_flipvehicle', 'Flip the nearest vehicle', 'keyboard', controls.flipVehicle)
RegisterCommand('frameos_vehicleradio', toggleRadio, false)
RegisterKeyMapping('frameos_vehicleradio', 'Toggle vehicle radio controls', 'keyboard', controls.toggleRadio)

FrameOS.command('cruise', 'toggles cruise control while driving', toggleCruise)
FrameOS.command('flipcar', 'flips the nearest vehicle', flipNearestVehicle)
FrameOS.command('vehicleradio', 'toggles vehicle radio controls', toggleRadio)

-- Prevent the game from moving a passenger into the driver seat automatically.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        if IsPedInAnyVehicle(ped, false) then
            SetPedConfigFlag(ped, 184, true)
            Wait(500)
        else
            Wait(1000)
        end
    end
end)

-- Restore movement state after a ped/model change.
FrameOS.onSpawn(function()
    ResetPedMovementClipset(PlayerPedId(), 1.0)
    ResetPedWeaponMovementClipset(PlayerPedId())
    ResetPedStrafeClipset(PlayerPedId())
    crouched = false
    cruiseSpeed = 0.0
end)

CreateThread(function()
    while true do
        if crouched and (IsPedInAnyVehicle(PlayerPedId(), false) or IsEntityDead(PlayerPedId())) then
            ResetPedMovementClipset(PlayerPedId(), 1.0)
            ResetPedWeaponMovementClipset(PlayerPedId())
            ResetPedStrafeClipset(PlayerPedId())
            crouched = false
        end
        Wait(500)
    end
end)

-- Rockstar's built-in clip editor controls.
local recording = false
RegisterCommand('frameos_editor', function()
    if recording then
        StopRecordingAndSaveClip()
        recording = false
        tell('Recording saved')
    else
        StartRecording(1)
        recording = true
        tell('Recording started')
    end
end, false)
RegisterKeyMapping('frameos_editor', 'Start or save a game recording', 'keyboard', controls.editor)
RegisterCommand('frameos_editordiscard', function()
    if recording then
        StopRecordingAndDiscardClip()
        recording = false
        tell('Recording discarded')
    else
        StopRecordingAndDiscardClip()
        tell('Recording editor closed')
    end
end, false)
RegisterCommand('record', function()
    StartRecording(1)
    recording = true
    tell('Recording started')
end, false)
RegisterCommand('clip', function()
    StartRecording(0)
    recording = true
    tell('Clip recording started')
end, false)
RegisterCommand('saveclip', function()
    StopRecordingAndSaveClip()
    recording = false
    tell('Recording saved')
end, false)
RegisterCommand('delclip', function()
    StopRecordingAndDiscardClip()
    recording = false
    tell('Recording discarded')
end, false)
RegisterCommand('editor', function()
    NetworkSessionLeaveSinglePlayer()
    ActivateRockstarEditor()
end, false)
FrameOS.command('recording', 'starts or saves a Rockstar game recording', function()
    ExecuteCommand('frameos_editor')
end)
