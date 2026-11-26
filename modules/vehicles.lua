-- vehicles: the cars you own. buy them in a shop, bring them out with /mycar.
-- only one car is out at a time, bringing out another removes the last one.
-- the SERVER keeps the list (server/economy.lua), with an id, plate and colors for each.
-- later, owned cars will be kept at your safehouses (garage), not brought out from anywhere.

FrameOS.command('mycars', 'lists the cars you own', function()
    local owned = FrameOS.data.owned
    if #owned == 0 then
        FrameOS.notify('You own no cars yet. Visit a shop.')
        return
    end
    for number, car in ipairs(owned) do
        FrameOS.notify(number .. ': ' .. car.name .. ' (' .. car.plate .. ')')
    end
end)

FrameOS.command('mycar', 'brings out one of your cars, example: /mycar 2', function(source, args)
    local number = tonumber(args[1]) or 1
    local car = FrameOS.data.owned[number]
    if car then
        FrameOS.spawnVehicle(car.model, nil, car)
    else
        FrameOS.notify('No car number ' .. number .. ' (see /mycars)')
    end
end)

-- gives you a car for free (admins). the car does not have to be in data/vehicles.lua,
-- any model the game has works, example: /givecar ellie
FrameOS.testCommand('givecar', 'gives you a car (admins), example: /givecar ellie', function(source, args)
    local model = args[1] and string.lower(args[1])
    if not model or not IsModelInCdimage(joaat(model)) or not IsModelAVehicle(joaat(model)) then
        FrameOS.notify('Usage: /givecar <model>  (the game has to know the model)')
        return
    end
    if FrameOS.request('admin', 'givecar', model, tonumber(args[2])) then
        FrameOS.notify('Added ' .. model .. ' to your cars')
    end
end)

-- selling needs "confirm" on the end so a typo can't sell a car
FrameOS.command('sellcar', 'sells a car for half its price, example: /sellcar 2 confirm', function(source, args)
    local number = tonumber(args[1])
    local car = number and FrameOS.data.owned[number]
    if not car then
        FrameOS.notify('Usage: /sellcar <number> confirm  (see /mycars)')
        return
    end
    if args[2] ~= 'confirm' then
        FrameOS.notify('Selling the ' .. car.name .. ' (' .. car.plate .. ') gets you '
            .. FrameOS.formatMoney(math.floor(car.price / 2)) .. '. Type /sellcar ' .. number .. ' confirm')
        return
    end
    local answer = FrameOS.request('sellVehicle', car.id)
    if answer then
        FrameOS.notify('Sold the ' .. answer.name)
    end
end)
