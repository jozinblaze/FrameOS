-- storage: the trunk and glovebox of cars you own, and the stash at a safehouse.
--   trunk     stand at the back of your car, press E
--   glovebox  sit in your car, press G
--   stash     at a safehouse circle, press G
-- the menu has two lists, YOU (your bag) and the container.
--   Left / Right switch list    Up / Down choose    Enter move one    Shift+Enter move all
--   Backspace leave
-- the server keeps everything and checks the weight (server/storage.lua).
-- sizes are in data/storage.lua. only cars you own have storage, it is kept by plate.

local using = false

local function weightOf(items)
    local total = 0
    for name, count in pairs(items) do
        if Items[name] and Items[name].weight then
            total = total + Items[name].weight * count
        end
    end
    return total
end

-- a sorted list of { name, label, count } for drawing
local function listOf(items)
    local list = {}
    for name, count in pairs(items) do
        local item = Items[name]
        table.insert(list, { name = name, label = item and item.label or (name .. ' (unknown)'), count = count })
    end
    table.sort(list, function(a, b) return a.label < b.label end)
    return list
end

local function kg(n)
    return string.format('%.1f', n)
end

-- draws one column of rows. returns nothing.
local function drawColumn(title, header, list, index, active, x)
    FrameOS.drawText(title, x, 0.26, 0.55, true, active and { 255, 220, 80 } or { 255, 255, 255 })
    FrameOS.drawText(header, x, 0.30, 0.38, true)
    if #list == 0 then
        FrameOS.drawText('(empty)', x, 0.35, 0.4, true, { 180, 180, 180 })
        return
    end
    local first = math.max(1, math.min(index - 4, #list - 8))
    for row = 0, 8 do
        local entry = list[first + row]
        if entry then
            local text = entry.label .. ' x' .. entry.count
            if first + row == index and active then
                FrameOS.drawText('> ' .. text .. ' <', x, 0.35 + row * 0.04, 0.45, true, { 255, 220, 80 })
            else
                FrameOS.drawText(text, x, 0.35 + row * 0.04, 0.42, true)
            end
        end
    end
end

-- opens the menu. kind is 'trunk', 'glove' or 'stash', ref is the plate or the safehouse name.
function FrameOS.openStorage(kind, ref)
    if using then
        return
    end
    local box = FrameOS.request('storageOpen', kind, ref)
    if not box then
        return
    end
    using = true
    local ped = PlayerPedId()
    local inCar = IsPedInAnyVehicle(ped, false)
    local vehicle = nil
    if kind == 'trunk' then
        vehicle = GetClosestVehicle(GetEntityCoords(ped), 6.0, 0, 71)
        if vehicle ~= 0 then
            SetVehicleDoorOpen(vehicle, 5, false, false)   -- door 5 is the trunk
        end
    end
    if not inCar then
        FreezeEntityPosition(ped, true)
    end

    local panel = 'bag'
    local indexBag, indexBox = 1, 1

    while using do
        Wait(0)
        if IsEntityDead(ped) then
            using = false
        end

        local bagList = listOf(FrameOS.data.bag)
        local boxList = listOf(box.items)
        if indexBag > #bagList then indexBag = math.max(1, #bagList) end
        if indexBox > #boxList then indexBox = math.max(1, #boxList) end

        FrameOS.drawText(box.label, 0.5, 0.17, 0.7, true)
        FrameOS.drawText('Cash ' .. FrameOS.formatMoney(FrameOS.getCash()), 0.5, 0.215, 0.4, true)
        drawColumn('You', kg(weightOf(FrameOS.data.bag)) .. ' / ' .. kg(FrameOS.bagLimit()) .. ' kg',
            bagList, indexBag, panel == 'bag', 0.33)
        drawColumn(box.label, kg(box.weight) .. ' / ' .. kg(box.size) .. ' kg',
            boxList, indexBox, panel == 'box', 0.67)
        FrameOS.drawText('Left/Right list   Up/Down choose   Enter one   Shift+Enter all   Backspace leave',
            0.5, 0.74, 0.34, true)

        if IsControlJustPressed(0, 174) or IsControlJustPressed(0, 175) then
            panel = panel == 'bag' and 'box' or 'bag'
        elseif IsControlJustPressed(0, 172) then
            if panel == 'bag' then
                indexBag = indexBag - 1
                if indexBag < 1 then indexBag = math.max(1, #bagList) end
            else
                indexBox = indexBox - 1
                if indexBox < 1 then indexBox = math.max(1, #boxList) end
            end
        elseif IsControlJustPressed(0, 173) then
            if panel == 'bag' then
                indexBag = #bagList > 0 and indexBag % #bagList + 1 or 1
            else
                indexBox = #boxList > 0 and indexBox % #boxList + 1 or 1
            end
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then
            local list = panel == 'bag' and bagList or boxList
            local entry = list[panel == 'bag' and indexBag or indexBox]
            if entry then
                local count = 1
                if IsControlPressed(0, 21) then   -- 21 is shift: move as many as fit
                    count = entry.count
                    local weight = Items[entry.name] and Items[entry.name].weight or 0
                    if weight > 0 then
                        local room
                        if panel == 'bag' then
                            room = box.size - box.weight
                        else
                            room = FrameOS.bagLimit() - weightOf(FrameOS.data.bag)
                        end
                        count = math.min(count, math.floor((room + 0.0001) / weight))
                    end
                end
                if count < 1 then
                    FrameOS.notify('Not enough room')
                    goto skip
                end
                local answer = FrameOS.request('storageMove', kind, ref, panel == 'bag' and 'in' or 'out', entry.name, count)
                if answer then
                    box = answer
                end
            end
            ::skip::
        elseif IsControlJustPressed(0, 177) then
            using = false
        end
    end

    if vehicle and vehicle ~= 0 and DoesEntityExist(vehicle) then
        SetVehicleDoorShut(vehicle, 5, false)
    end
    FreezeEntityPosition(PlayerPedId(), false)
end

-- finds the car you own with this plate (the car's own data), or nil
local function ownedCar(vehicle)
    local plate = GetVehicleNumberPlateText(vehicle)
    if not plate then
        return nil
    end
    plate = plate:match('^%s*(.-)%s*$')
    for _, car in ipairs(FrameOS.data.owned) do
        if car.plate == plate then
            return car, plate
        end
    end
    return nil
end

-- where the trunk is on a car
local function trunkPosition(vehicle)
    local bone = GetEntityBoneIndexByName(vehicle, 'boot')
    if bone ~= -1 then
        return GetWorldPositionOfEntityBone(vehicle, bone)
    end
    local min = GetModelDimensions(GetEntityModel(vehicle))
    return GetOffsetFromEntityInWorldCoords(vehicle, 0.0, min.y, 0.0)
end

-- the prompts. nothing near: check four times a second.
CreateThread(function()
    while true do
        local sleep = 250
        local ped = PlayerPedId()
        if not using and not IsEntityDead(ped) then
            if IsPedInAnyVehicle(ped, false) then
                local car, plate = ownedCar(GetVehiclePedIsIn(ped, false))
                -- only offer it when the car is nearly stopped, the prompt is distracting while driving
                if car and GetEntitySpeed(GetVehiclePedIsIn(ped, false)) < 1.0 then
                    sleep = 0
                    FrameOS.help('Press ~INPUT_DETONATE~ to open the glovebox')
                    if IsControlJustPressed(0, 47) then   -- 47 is the G key
                        FrameOS.openStorage('glove', plate)
                    end
                end
            else
                local coords = GetEntityCoords(ped)
                local vehicle = GetClosestVehicle(coords.x, coords.y, coords.z, 6.0, 0, 71)
                if vehicle ~= 0 then
                    local car, plate = ownedCar(vehicle)
                    if car and Config.trunkCapacity(car.model) > 0
                        and #(coords - trunkPosition(vehicle)) < 1.8 then
                        sleep = 0
                        FrameOS.help('Press ~INPUT_CONTEXT~ to open the trunk')
                        if IsControlJustPressed(0, 38) then   -- 38 is the E key
                            FrameOS.openStorage('trunk', plate)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)
