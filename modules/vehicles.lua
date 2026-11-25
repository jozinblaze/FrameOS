-- vehicles: the cars you own. buy them in a shop, bring them out with /mycar.
-- only one car is out at a time, bringing out another removes the last one.

-- your cars: a list of { model, name, price }
local owned = FrameOS.load('owned', {})

-- the shop calls this when you buy something
function FrameOS.ownVehicle(model, name, price)
    table.insert(owned, { model = model, name = name, price = price })
    FrameOS.save('owned', owned)
end

FrameOS.command('mycars', 'lists the cars you own', function()
    if #owned == 0 then
        FrameOS.notify('You own no cars yet. Visit a shop.')
        return
    end
    for number, car in ipairs(owned) do
        FrameOS.notify(number .. ': ' .. car.name)
    end
end)

FrameOS.command('mycar', 'brings out one of your cars, example: /mycar 2', function(source, args)
    local number = tonumber(args[1]) or 1
    local car = owned[number]
    if car then
        FrameOS.spawnVehicle(car.model)
    else
        FrameOS.notify('No car number ' .. number .. ' (see /mycars)')
    end
end)

FrameOS.command('sellcar', 'sells one of your cars for half its price, example: /sellcar 2', function(source, args)
    local number = tonumber(args[1])
    local car = number and owned[number]
    if not car then
        FrameOS.notify('Usage: /sellcar <number>  (see /mycars)')
        return
    end
    table.remove(owned, number)
    FrameOS.save('owned', owned)
    FrameOS.addCash(math.floor(car.price / 2))
    FrameOS.notify('Sold the ' .. car.name)
end)
