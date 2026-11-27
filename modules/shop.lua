-- shop: stores and car dealerships. walk into a shop's circle and press E.
--   item shops:    Up / Down choose, Enter buy one, Backspace leave
--   vehicle shops: Left / Right browse, Enter buy, Backspace leave
-- where the shops are and what they sell is in data/shops.lua.
-- /setshop makes your own where you stand, /stocks lists what a shop can sell.

local mine = FrameOS.load('shops', {})   -- shops you made in game
local shops = {}                         -- the presets plus yours
local blips = {}                         -- map icons we made, so we can redo them
local browsing = false                   -- true while a shop screen is open

-- map icons for shops that don't set their own
local defaultBlips = {
    items = { sprite = 52, color = 2 },
    vehicles = { sprite = 326, color = 3 },
}

-- shops saved before shop types existed have no type, they were car shops
local function shopType(shop)
    return shop.type or 'vehicles'
end

-- the stock list a shop sells. shops saved long ago have none written down.
local function stockOf(shop)
    if shop.stock then
        return shop.stock
    end
    if shopType(shop) == 'vehicles' then
        return 'dealership'
    end
    return 'normal'
end

local function rebuild()
    shops = {}
    for id, shop in pairs(Config.shops) do
        shops[id] = shop
    end
    for id, shop in pairs(mine) do
        shops[id] = shop
    end

    -- redo the map icons
    FrameOS.removeBlips(blips)
    blips = {}
    for id, shop in pairs(shops) do
        local look = shop.blip or defaultBlips[shopType(shop)] or defaultBlips.items
        local blip = FrameOS.addBlip(shop.x, shop.y, shop.z, look.sprite, look.color, shop.label or id)
        if blip then
            table.insert(blips, blip)
        end
    end
end

rebuild()

-- the cars a shop sells, as a list. cars this game build doesn't have are skipped.
local function vehicleList(stockName)
    local list = {}
    for _, model in ipairs(Config.stock[stockName] or {}) do
        local info = Vehicles[model]
        if info and IsModelInCdimage(joaat(model)) then
            table.insert(list, { model = model, name = info.name, price = info.price, category = info.category })
        end
    end
    return list
end

-- the items a shop sells, as a list. an entry can be a name,
-- or { name = 'pisswasser', price = 9 } to charge a different price here.
local function itemList(stockName)
    local list = {}
    for _, entry in ipairs(Config.stock[stockName] or {}) do
        local name = entry
        local price = nil
        if type(entry) == 'table' then
            name = entry.name
            price = entry.price
        end
        local info = Items[name]
        if info then
            table.insert(list, { name = name, label = info.label, price = price or info.price })
        end
    end
    return list
end

local function browseItems(shop, id)
    browsing = true
    local ped = PlayerPedId()
    local list = itemList(shop.stock or 'normal')
    if #list == 0 then
        FrameOS.notify('This shop has nothing to sell')
        browsing = false
        return
    end

    FreezeEntityPosition(ped, true)
    local index = 1

    while browsing do
        Wait(0)
        if IsEntityDead(ped) then   -- dying closes the shop, or you'd respawn frozen
            browsing = false
        end

        -- show up to 9 rows, keeping the selected one in view
        local first = math.max(1, math.min(index - 4, #list - 8))

        FrameOS.drawText(shop.label, 0.5, 0.17, 0.7, true)
        FrameOS.drawText('Cash ' .. FrameOS.formatMoney(FrameOS.getCash()), 0.5, 0.215, 0.4, true)

        for row = 0, 8 do
            local entry = list[first + row]
            if entry then
                local text = entry.label .. '   ' .. FrameOS.formatMoney(entry.price)
                if first + row == index then
                    FrameOS.drawText('> ' .. text .. ' <', 0.5, 0.26 + row * 0.04, 0.5, true, { 255, 220, 80 })
                else
                    FrameOS.drawText(text, 0.5, 0.26 + row * 0.04, 0.45, true)
                end
            end
        end

        FrameOS.drawText('Up / Down choose     Enter buy one     Backspace leave', 0.5, 0.64, 0.4, true)

        if IsControlJustPressed(0, 172) then                       -- up arrow
            index = index - 1
            if index < 1 then
                index = #list
            end
        elseif IsControlJustPressed(0, 173) then                   -- down arrow
            index = index % #list + 1
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then   -- enter
            local entry = list[index]
            -- canGive first so you aren't charged for something you can't take.
            -- the server checks the shop, the price and that you are standing there.
            if FrameOS.canGive(entry.name) then
                local answer = FrameOS.request('buyItem', id, entry.name, stockOf(shop))
                if answer then
                    FrameOS.applyItem(entry.name)
                end
            end
        elseif IsControlJustPressed(0, 177) then                   -- backspace
            browsing = false
        end
    end

    FreezeEntityPosition(PlayerPedId(), false)
end

local function browseVehicles(shop, id)
    browsing = true
    local ped = PlayerPedId()
    local cars = vehicleList(shop.stock or 'dealership')
    if #cars == 0 then
        FrameOS.notify('This shop has nothing to sell')
        browsing = false
        return
    end

    FreezeEntityPosition(ped, true)

    -- the display car stands on the shop's preview spot (data/shops.lua).
    -- a shop without one shows it 6 meters in front of you, which is fine for /setshop shops.
    -- where the display car stands: the shop's preview spot, or 6 meters in front of you
    local spot, heading
    if shop.preview then
        spot = vector3(shop.preview.x, shop.preview.y, shop.preview.z)
        heading = shop.preview.h or 0.0
    else
        spot = GetOffsetFromEntityInWorldCoords(ped, 0.0, 6.0, 0.0)
        heading = GetEntityHeading(ped) + 90.0
    end

    local index = 1
    local preview = nil
    local bought = false

    local function removePreview()
        if preview and DoesEntityExist(preview) then
            SetEntityAsMissionEntity(preview, true, true)
            DeleteEntity(preview)
        end
        preview = nil
    end

    local function showCar()
        removePreview()
        local model = joaat(cars[index].model)
        if not FrameOS.loadModel(model) then
            FrameOS.notify(cars[index].name .. ' could not be shown')
            return
        end
        -- false, false = only you can see it
        preview = CreateVehicle(model, spot.x, spot.y, spot.z, heading, false, false)
        SetVehicleOnGroundProperly(preview)
        FreezeEntityPosition(preview, true)
        SetVehicleDoorsLocked(preview, 2)
        SetModelAsNoLongerNeeded(model)
    end

    showCar()

    while browsing do
        Wait(0)
        if IsEntityDead(ped) then
            browsing = false
        end
        local car = cars[index]
        FrameOS.drawText(car.name .. '   ' .. FrameOS.formatMoney(car.price), 0.5, 0.82, 0.7, true)
        FrameOS.drawText(car.category or '', 0.5, 0.875, 0.4, true)
        FrameOS.drawText('Left / Right browse     Enter buy     Backspace leave', 0.5, 0.91, 0.4, true)

        if IsControlJustPressed(0, 175) then                       -- right arrow
            index = index % #cars + 1
            showCar()
        elseif IsControlJustPressed(0, 174) then                   -- left arrow
            index = (index - 2) % #cars + 1
            showCar()
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then   -- enter
            -- the server charges you and makes the car (with its plate) if it all checks out
            local answer = FrameOS.request('buyVehicle', id, car.model, stockOf(shop))
            if answer then
                bought = answer.car   -- the saved car entry
                browsing = false
            end
        elseif IsControlJustPressed(0, 177) then                   -- backspace
            browsing = false
        end
    end

    removePreview()
    FreezeEntityPosition(PlayerPedId(), false)

    if bought and not IsEntityDead(PlayerPedId()) then
        FrameOS.notify('Bought the ' .. cars[index].name)
        -- the car appears at the shop's spawn spot if it has one (shop.spawn in data/shops.lua)
        -- and gets the plate and colors that were saved when you bought it
        FrameOS.spawnVehicle(cars[index].model, shop.spawn, bought)
    end
end

CreateThread(function()
    while true do
        -- nothing nearby: check twice a second. something near: every frame.
        local sleep = 500
        if not browsing then
            local coords = GetEntityCoords(PlayerPedId())
            for id, shop in pairs(shops) do
                local dist = #(coords - vector3(shop.x, shop.y, shop.z))
                if dist < 30.0 then
                    sleep = 0
                    local isItems = shopType(shop) == 'items'

                    -- the circle on the ground: green for stores, blue for dealerships
                    local r, g, b = 60, 140, 255
                    if isItems then
                        r, g, b = 80, 200, 120
                    end
                    DrawMarker(1, shop.x, shop.y, shop.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.5, 1.5, 0.6,
                        r, g, b, 150,
                        false, false, 2, false, nil, nil, false)

                    -- store counters are a bit out of reach, so they get a wider circle
                    local radius = 1.5
                    if isItems then
                        radius = 2.0
                    end

                    -- shops only open while you're on foot
                    if dist < radius and not IsPedInAnyVehicle(PlayerPedId(), false) then
                        if isItems then
                            FrameOS.help('Press ~INPUT_CONTEXT~ to shop')
                        else
                            FrameOS.help('Press ~INPUT_CONTEXT~ to browse cars')
                        end
                        if IsControlJustPressed(0, 38) then   -- 38 is the E key
                            if isItems then
                                browseItems(shop, id)
                            else
                                browseVehicles(shop, id)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

FrameOS.testCommand('setshop', 'makes a shop where you stand, example: /setshop beachstore items normal', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /setshop <name> [items or vehicles] [stock]  (see /stocks)')
        return
    end

    local name = string.lower(args[1])
    local kind = args[2] or 'vehicles'
    if kind ~= 'items' and kind ~= 'vehicles' then
        FrameOS.notify('The type has to be items or vehicles')
        return
    end

    -- no stock given: stores sell the normal list, dealerships the dealership list
    local stock = 'dealership'
    if kind == 'items' then
        stock = 'normal'
    end
    if args[3] then
        stock = string.lower(args[3])
    end
    if not Config.stock[stock] then
        FrameOS.notify('No stock list called ' .. stock .. ' (see /stocks)')
        return
    end

    local coords = GetEntityCoords(PlayerPedId())
    mine[name] = { label = name, type = kind, stock = stock, x = coords.x, y = coords.y, z = coords.z }
    FrameOS.save('shops', mine)
    rebuild()
    FrameOS.notify('Shop saved: ' .. name .. ' (' .. kind .. ', ' .. stock .. ')')
end)

FrameOS.testCommand('delshop', 'removes a shop you made', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /delshop <name>')
        return
    end
    local name = string.lower(args[1])
    if mine[name] then
        mine[name] = nil
        FrameOS.save('shops', mine)
        rebuild()
        FrameOS.notify('Removed shop: ' .. name)
    else
        FrameOS.notify('You have no shop called ' .. name)
    end
end)

FrameOS.testCommand('shops', 'prints every shop in the F8 console', function()
    local count = 0
    for id, shop in pairs(shops) do
        print(id .. ' (' .. shopType(shop) .. ', ' .. (shop.stock or 'dealership') .. ')')
        count = count + 1
    end
    FrameOS.notify(count .. ' shops, list printed in the F8 console')
end)

FrameOS.testCommand('stocks', 'lists the stock lists a shop can sell', function()
    local names = {}
    for name, _ in pairs(Config.stock) do
        table.insert(names, name)
    end
    table.sort(names)
    FrameOS.notify('Stock lists: ' .. table.concat(names, ', '))
end)

FrameOS.addExport(function()
    local lines = { '-- shops: paste these at the bottom of data/shops.lua instead of config.lua' }
    for id, s in pairs(mine) do
        table.insert(lines, string.format(
            "Config.shops['%s'] = { label = '%s', type = '%s', stock = '%s', x = %.2f, y = %.2f, z = %.2f }",
            id, s.label or id, shopType(s), s.stock or 'dealership', s.x, s.y, s.z))
    end
    return lines
end)
