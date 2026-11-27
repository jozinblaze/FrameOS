-- Ambient world options and optional map-object cleanup.

local settings = Config.population

CreateThread(function()
    if settings.disableWanted then SetMaxWantedLevel(0)
    else SetMaxWantedLevel(settings.maxWantedLevel or 5) end

    for service = 1, 15 do
        local enabled = settings.dispatch[service]
        if enabled ~= nil then EnableDispatchService(service, enabled) end
    end
    SetCreateRandomCops(not settings.disableRandomCops)
    SetCreateRandomCopsNotOnScenarios(not settings.disableRandomCops)
    SetCreateRandomCopsOnScenarios(not settings.disableRandomCops)
    SetGarbageTrucks(not settings.disableGarbageTrucks)
    SetRandomBoats(not settings.disableRandomBoats)
    if settings.disableAmbience then
        StartAudioScene('CHARACTER_CHANGE_IN_SKY_SCENE')
        SetAudioFlag('PoliceScannerDisabled', true)
        DistantCopCarSirens(false)
    end
end)

-- Scenario and model suppression needs to be reapplied after some map transitions.
CreateThread(function()
    while true do
        for _, scenario in ipairs(settings.disabledScenarioTypes or {}) do
            SetScenarioTypeEnabled(scenario, false)
        end
        for _, model in ipairs(settings.suppressedVehicleModels or {}) do
            SetVehicleModelIsSuppressed(joaat(model), true)
        end
        for _, group in ipairs(settings.disabledScenarioGroups or {}) do
            SetScenarioGroupEnabled(group, false)
        end
        Wait(10000)
    end
end)

if settings.disableIdleCamera then
    CreateThread(function()
        while true do
            DisableIdleCamera(true)
            DisableVehiclePassengerIdleCamera(true)
            Wait(1000)
        end
    end)
end

if settings.noAmbientHeadshots then
    CreateThread(function()
        while true do
            SetPedSuffersCriticalHits(PlayerPedId(), false)
            Wait(1000)
        end
    end)
end

-- Delete only explicitly configured map objects, and only in a small radius.
CreateThread(function()
    local objects = Config.removedWorldObjects or {}
    if #objects == 0 then return end
    while true do
        for _, entry in ipairs(objects) do
            local hash = type(entry.model) == 'number' and entry.model or joaat(entry.model)
            local radius = entry.radius or 2.0
            local object = GetClosestObjectOfType(entry.x, entry.y, entry.z, radius, hash, false, false, false)
            if object ~= 0 and DoesEntityExist(object) then
                SetEntityAsMissionEntity(object, true, true)
                DeleteObject(object)
            end
        end
        Wait(5000)
    end
end)

-- Configure static emitter names as { ['emitter_name'] = false } to disable.
if Config.staticEmitterSettings.enabled then
    for name, enabled in pairs(Config.staticEmitterSettings.emitters or {}) do
        SetStaticEmitterEnabled(name, enabled)
    end
    for _, name in ipairs(Config.staticEmitterSettings.disable or {}) do
        SetStaticEmitterEnabled(name, false)
    end
end

