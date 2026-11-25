-- vehicles: the cars you own. buy them in a shop, bring them out with /mycar.
-- only one car is out at a time, bringing out another removes the last one.
-- later, owned cars will be kept at your safehouses (garage), not brought out from anywhere.

-- your cars: a list of { id, model, name, price, plate, primary, secondary }
local owned = FrameOS.load('owned', {})
local nextId = FrameOS.load('owned_next', 1)

-- paint colors a new car can come in (the game's color numbers)
local paints = { 0, 111, 27, 64, 4, 88, 42, 53 }   -- black, white, red, blue, grey, yellow, orange, green

local function newPlate()
    local chars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789'
    local plate = 'FR'
    for _ = 1, 6 do
        local n = math.random(1, #chars)
        plate = plate .. chars:sub(n, n)
    end
    return plate
end

-- cars saved before v0.9.0 had no id, plate or colors, so give them some once
for _, car in ipairs(owned) do
    if not car.id then
        car.id = nextId
        nextId = nextId + 1
        car.plate = newPlate()
        car.primary = paints[math.random(1, #paints)]
        car.secondary = car.primary
    end
end
FrameOS.save('owned', owned)
FrameOS.save('owned_next', nextId)

-- the shop calls this when you buy something. it returns the saved car,
-- which has the plate and colors the car should be spawned with.
function FrameOS.ownVehicle(model, name, price)
    local color = paints[math.random(1, #paints)]
    local car = {
        id = nextId, model = model, name = name, price = price,
        plate = newPlate(), primary = color, secondary = color,
    }
    nextId = nextId + 1
    table.insert(owned, car)
    FrameOS.save('owned', owned)
    FrameOS.save('owned_next', nextId)
    return car
end

FrameOS.command('mycars', 'lists the cars you own', function()
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
    local car = owned[number]
    if car then
        FrameOS.spawnVehicle(car.model, nil, car)
    else
        FrameOS.notify('No car number ' .. number .. ' (see /mycars)')
    end
end)

-- selling needs "confirm" on the end so a typo can't sell a car
FrameOS.command('sellcar', 'sells a car for half its price, example: /sellcar 2 confirm', function(source, args)
    local number = tonumber(args[1])
    local car = number and owned[number]
    if not car then
        FrameOS.notify('Usage: /sellcar <number> confirm  (see /mycars)')
        return
    end
    if args[2] ~= 'confirm' then
        FrameOS.notify('Selling the ' .. car.name .. ' (' .. car.plate .. ') gets you '
            .. FrameOS.formatMoney(math.floor(car.price / 2)) .. '. Type /sellcar ' .. number .. ' confirm')
        return
    end
    table.remove(owned, number)
    FrameOS.save('owned', owned)
    FrameOS.addCash(math.floor(car.price / 2))
    FrameOS.notify('Sold the ' .. car.name)
end)
