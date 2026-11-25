-- garage: spawn cars and keep a favorites list

local lastCar = nil                          -- so we can remove the previous one
local carBlip = nil                         -- the map icon for your car
local favorites = FrameOS.load('favorites', {})   -- a plain list of model names

-- puts you in a new car.
-- at is optional, a spot like { x, y, z, h }. without it the car appears where you stand.
-- look is optional too, an owned car with a plate, primary and secondary color.
local function spawnCar(modelName, at, look)
    local model = joaat(modelName)

    -- make sure it's a real vehicle before doing anything
    if not IsModelInCdimage(model) or not IsModelAVehicle(model) then
        FrameOS.notify('No vehicle called ' .. modelName)
        return
    end

    -- ask for the model, then wait until it's loaded
    RequestModel(model)
    while not HasModelLoaded(model) do
        Wait(0)
    end

    local ped = PlayerPedId()
    local coords = GetEntityCoords(ped)
    local heading = GetEntityHeading(ped)

    -- a shop can give a spot for the car to appear at
    if at then
        coords = vector3(at.x, at.y, at.z)
        heading = at.h or heading
    end

    -- remove the previous car so they don't pile up
    if lastCar and DoesEntityExist(lastCar) then
        DeleteEntity(lastCar)
    end
    if carBlip and DoesBlipExist(carBlip) then
        RemoveBlip(carBlip)
    end

    lastCar = CreateVehicle(model, coords.x, coords.y, coords.z, heading, true, false)
    if look then
        SetVehicleColours(lastCar, look.primary or 0, look.secondary or 0)
        SetVehicleNumberPlateText(lastCar, look.plate or 'FRAMEOS')
    end
    SetPedIntoVehicle(ped, lastCar, -1)   -- -1 = driver seat
    SetModelAsNoLongerNeeded(model)

    -- the icon depends on what kind of vehicle it is, the name is the model's real name
    -- (Bati 801, Sultan...). 3 is blue. it follows the vehicle around on the map.
    local class = GetVehicleClass(lastCar)
    local sprite = 225                       -- car
    if class == 8 or class == 13 then sprite = 226     -- motorcycle, bicycle
    elseif class == 14 then sprite = 427               -- boat
    elseif class == 15 then sprite = 422               -- helicopter
    elseif class == 16 then sprite = 423               -- plane
    elseif class == 10 or class == 11 or class == 20 then sprite = 477   -- trucks
    end
    local label = GetLabelText(GetDisplayNameFromVehicleModel(model))
    if label == 'NULL' then label = modelName end
    carBlip = FrameOS.addEntityBlip(lastCar, sprite, 3, GetPlayerName(PlayerId()) .. "'s " .. label)
    return lastCar
end

-- the car icon only shows while you are NOT in the car.
-- SetBlipAlpha 0 hides it, 255 shows it.
CreateThread(function()
    while true do
        if carBlip and DoesBlipExist(carBlip) then
            local inside = lastCar and DoesEntityExist(lastCar) and GetVehiclePedIsIn(PlayerPedId(), false) == lastCar
            SetBlipAlpha(carBlip, inside and 0 or 255)
        end
        Wait(500)
    end
end)

-- the vehicles and shop modules use this too
FrameOS.spawnVehicle = spawnCar

FrameOS.testCommand('car', 'spawns a car, example: /car sultan', function(source, args)
    spawnCar(args[1] or 'adder')
end)

FrameOS.testCommand('fav', 'saves the car you are sitting in', function()
    local vehicle = GetVehiclePedIsIn(PlayerPedId(), false)
    if vehicle == 0 then
        FrameOS.notify('Sit in a car first, then use /fav')
        return
    end

    -- the game gives us the model's short name, like SULTAN
    local name = string.lower(GetDisplayNameFromVehicleModel(GetEntityModel(vehicle)))

    -- don't save the same car twice
    for _, saved in ipairs(favorites) do
        if saved == name then
            FrameOS.notify(name .. ' is already a favorite')
            return
        end
    end

    table.insert(favorites, name)
    FrameOS.save('favorites', favorites)
    FrameOS.notify('Saved ' .. name .. ' as favorite #' .. #favorites)
end)

FrameOS.testCommand('favs', 'lists your favorite cars with numbers', function()
    if #favorites == 0 then
        FrameOS.notify('No favorites yet. Sit in a car and use /fav')
        return
    end
    for number, name in ipairs(favorites) do
        FrameOS.notify(number .. ': ' .. name)
    end
end)

FrameOS.testCommand('favcar', 'spawns a favorite, example: /favcar 2', function(source, args)
    local number = tonumber(args[1])
    if number and favorites[number] then
        spawnCar(favorites[number])
    else
        FrameOS.notify('Usage: /favcar <number>  (see /favs)')
    end
end)

FrameOS.testCommand('unfav', 'removes a favorite, example: /unfav 2', function(source, args)
    local number = tonumber(args[1])
    if number and favorites[number] then
        local name = table.remove(favorites, number)
        FrameOS.save('favorites', favorites)
        FrameOS.notify('Removed ' .. name)
    else
        FrameOS.notify('Usage: /unfav <number>  (see /favs)')
    end
end)
