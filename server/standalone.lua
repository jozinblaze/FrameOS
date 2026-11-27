-- Server authority for the standalone utilities: AFK tracking, entity rules,
-- tackles, and synchronized vehicle pushing.

local activity = {}
local warnedAt = {}
local lastHeartbeat = {}
local lastTackle = {}
local lastPushUpdate = {}
local pushingVehicles = {}
local blockedModels = {}
local vehicleConfig = Config.vehicleUtilities

for _, model in ipairs(Config.entityRestrictions.blockedModels or {}) do
    blockedModels[joaat(model)] = true
end

if next(blockedModels) then
    AddEventHandler('entityCreating', function(entity)
        if entity ~= 0 and blockedModels[GetEntityModel(entity)] then
            CancelEvent()
        end
    end)
end

local function notifyClient(player, message)
    TriggerClientEvent('frameos:standaloneNotify', player, message)
end

local function removePlayerData(player)
    activity[player] = nil
    warnedAt[player] = nil
    lastHeartbeat[player] = nil
    lastTackle[player] = nil
    lastPushUpdate[player] = nil
end

AddEventHandler('playerJoining', function()
    local player = source
    activity[player] = os.time()
end)

AddEventHandler('playerDropped', function()
    local player = source
    local vehicle = pushingVehicles[player]
    if vehicle and DoesEntityExist(vehicle) then
        local state = Entity(vehicle).state
        if state.frameosPushOwner == player then
            state:set('frameosPushDirection', nil, true)
            state:set('frameosPushOwner', nil, true)
        end
    end
    pushingVehicles[player] = nil
    removePlayerData(player)
end)

RegisterNetEvent('frameos:activity', function()
    local player = source
    local now = os.time()
    -- A heartbeat only refreshes the sender's own AFK clock. Rate limiting
    -- keeps a modified client from flooding the server with this no-op event.
    if lastHeartbeat[player] and now - lastHeartbeat[player] < 10 then return end
    lastHeartbeat[player] = now
    activity[player] = now
    warnedAt[player] = nil
end)

if Config.afk.enabled then
    CreateThread(function()
        while true do
            Wait(math.max(5, Config.afk.checkEvery or 15) * 1000)
            local now = os.time()
            for _, id in ipairs(GetPlayers()) do
                local player = tonumber(id)
                if player and not FrameOS.isAdmin(player) then
                    activity[player] = activity[player] or now
                    local remaining = (Config.afk.timeout or 1800) - (now - activity[player])
                    if remaining <= 0 then
                        DropPlayer(player, 'Disconnected for inactivity')
                        removePlayerData(player)
                    else
                        for _, warning in ipairs(Config.afk.warningAt or {}) do
                            if remaining <= warning and warnedAt[player] ~= warning then
                                warnedAt[player] = warning
                                local unit = warning >= 60 and 'minute(s)' or 'second(s)'
                                local amount = warning >= 60 and math.ceil(warning / 60) or warning
                                notifyClient(player, ('AFK warning: you will be disconnected in %d %s.'):format(amount, unit))
                            end
                        end
                    end
                end
            end
        end
    end)
end

-- Tackles are requests, never instructions to ragdoll an arbitrary player.
local tackleCooldown = 2500
RegisterNetEvent('frameos:tryTackle', function(target)
    local player = source
    if type(target) ~= 'number' or target % 1 ~= 0 or target == player then return end
    local now = GetGameTimer()
    if lastTackle[player] and now - lastTackle[player] < tackleCooldown then return end

    local attacker = GetPlayerPed(player)
    local victim = GetPlayerPed(target)
    if attacker == 0 or victim == 0 then return end
    if GetVehiclePedIsIn(attacker, false) ~= 0 or GetVehiclePedIsIn(victim, false) ~= 0 then return end
    if GetEntitySpeed(attacker) < 2.5 then return end
    if #(GetEntityCoords(attacker) - GetEntityCoords(victim)) > 2.0 then return end

    lastTackle[player] = now
    TriggerClientEvent('frameos:tackled', target)
end)

local pushDirections = { left = true, right = true, front = true, back = true }
RegisterNetEvent('frameos:vehiclePush', function(payload)
    local player = source
    if type(payload) ~= 'table' or type(payload.netId) ~= 'number'
        or payload.netId % 1 ~= 0 then return end
    if payload.direction ~= nil then
        local now = GetGameTimer()
        if lastPushUpdate[player] and now - lastPushUpdate[player] < 100 then return end
        lastPushUpdate[player] = now
    end

    local entity = NetworkGetEntityFromNetworkId(payload.netId)
    if entity == 0 or not DoesEntityExist(entity) or GetEntityType(entity) ~= 2 then return end
    local ped = GetPlayerPed(player)
    if ped == 0 then return end
    if #(GetEntityCoords(ped) - GetEntityCoords(entity)) > 5.0 then return end

    local state = Entity(entity).state
    if payload.direction == nil then
        if state.frameosPushOwner == player then
            state:set('frameosPushDirection', nil, true)
            state:set('frameosPushOwner', nil, true)
            pushingVehicles[player] = nil
        end
        return
    end

    if not pushDirections[payload.direction] or GetVehiclePedIsIn(ped, false) ~= 0
        or GetPedInVehicleSeat(entity, -1) ~= 0 then return end

    local class = GetVehicleClass(entity)
    for _, blocked in ipairs(vehicleConfig.pushBlacklistedClasses or {}) do
        if class == blocked then return end
    end
    local engine = GetVehicleEngineHealth(entity)
    if engine > (vehicleConfig.pushEngineHealth or 1000.0) then return end
    if state.frameosPushOwner and state.frameosPushOwner ~= player then return end
    if pushingVehicles[player] and pushingVehicles[player] ~= entity then return end

    pushingVehicles[player] = entity
    state:set('frameosPushOwner', player, true)
    state:set('frameosPushDirection', payload.direction, true)
end)
