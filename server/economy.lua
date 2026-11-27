-- economy: money, the bag and owned cars, kept on the server.
-- the client never says "give me $500". it says "I bought a burger at this shop",
-- and the server checks the shop, the price and that you are standing there.
--
-- every answer is a table: { ok = true, ... } or { ok = false, why = 'text for the player' }.
-- after any change the server sends the player their whole data (FrameOS.push),
-- and the client just shows what it was sent.
--
-- in this file:  balances, import of old saves, buying items and cars, selling a car,
--                using an item, cash pickups, the hospital bill, job pay (checked against
--                the job's data), food and drink use (needs are in needs.lua), the bank and ATMs (storage is in storage.lua), and the admin test commands.

local function data(source)
    return FrameOS.getPlayer(source)
end

local function no(why)
    return { ok = false, why = why }
end

-- how heavy a list of items is (name -> count). an item that is not in data/items.lua weighs nothing.
function FrameOS.weightOf(items)
    local total = 0
    for name, count in pairs(items) do
        local item = Items[name]
        if item and item.weight then
            total = total + item.weight * count
        end
    end
    return total
end

-- how much more cash the ATMs will give this player today
local function atmLeft(d)
    if d.atmDay ~= os.date('%Y%m%d') then
        return Config.atmDailyLimit
    end
    return math.max(0, Config.atmDailyLimit - (d.atmOut or 0))
end

-- sends the player's data to their screen
function FrameOS.push(source)
    local d = data(source)
    if d then
        TriggerClientEvent('frameos:data', source, {
            cash = d.cash, bank = d.bank, atmLeft = atmLeft(d), bag = d.bag, owned = d.owned, jobrep = d.jobrep,
            needs = d.needs,
        })
    end
end

-- ---------------------------------------------------------------- balances

-- other server code uses these. they return true if it worked.
function FrameOS.addCash(source, amount, reason)
    local d = data(source)
    amount = math.floor(tonumber(amount) or 0)
    if not d or amount <= 0 then
        return false
    end
    d.cash = d.cash + amount
    FrameOS.markDirty(source)
    FrameOS.log('cash', source, '+' .. amount .. ' (' .. (reason or '?') .. ') now ' .. d.cash)
    FrameOS.push(source)
    return true
end

function FrameOS.takeCash(source, amount, reason)
    local d = data(source)
    amount = math.floor(tonumber(amount) or 0)
    if not d or amount <= 0 or d.cash < amount then
        return false
    end
    d.cash = d.cash - amount
    FrameOS.markDirty(source)
    FrameOS.log('cash', source, '-' .. amount .. ' (' .. (reason or '?') .. ') now ' .. d.cash)
    FrameOS.push(source)
    return true
end

-- ---------------------------------------------------------------- helpers

local function near(source, x, y, z, range)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false
    end
    return #(GetEntityCoords(ped) - vector3(x, y, z)) <= range
end

-- finds a shop. the shops in data/shops.lua are checked by position.
-- a shop you built in game with /setshop only exists on your computer, so the server
-- can only trust it for admins while Config.testCommands is on.
local function findShop(source, shopId, claimedType, claimedStock)
    local shop = type(shopId) == 'string' and Config.shops[shopId]
    if shop then
        if not near(source, shop.x, shop.y, shop.z, 8.0) then
            return nil, 'You are too far from the shop'
        end
        return shop
    end
    if Config.testCommands and FrameOS.isAdmin(source)
        and type(claimedStock) == 'string' and Config.stock[claimedStock] then
        return { type = claimedType, stock = claimedStock }
    end
    return nil, 'Unknown shop'
end

-- the price a shop charges for something in its stock list, or nil if it does not sell it
local function stockPrice(stockName, name, vehicles)
    for _, entry in ipairs(Config.stock[stockName] or {}) do
        local entryName, entryPrice = entry, nil
        if type(entry) == 'table' then
            entryName = entry.name
            entryPrice = entry.price
        end
        if entryName == name then
            if vehicles then
                return Vehicles[name] and Vehicles[name].price
            end
            return entryPrice or (Items[name] and Items[name].price)
        end
    end
    return nil
end

local plateChars = 'ABCDEFGHJKLMNPRSTUVWXYZ0123456789'
local paints = { 0, 111, 27, 64, 4, 88, 42, 53 }   -- black, white, red, blue, grey, yellow, orange, green

local function newPlate()
    local plate = 'FR'
    for _ = 1, 6 do
        local n = math.random(1, #plateChars)
        plate = plate .. plateChars:sub(n, n)
    end
    return plate
end

local function newCar(d, model, name, price)
    local color = paints[math.random(1, #paints)]
    local car = {
        id = d.nextCarId, model = model, name = name, price = price,
        plate = newPlate(), primary = color, secondary = color,
    }
    d.nextCarId = d.nextCarId + 1
    table.insert(d.owned, car)
    return car
end

-- ---------------------------------------------------------------- import of old saves

-- the first time you join, the client sends what it had saved on your own computer.
-- this can only happen once, the numbers are capped, and it is logged.
FrameOS.onAsk('import', function(source, payload)
    local d = data(source)
    if d.imported then
        return no('already imported')
    end
    if type(payload) ~= 'table' or Config.importEnabled == false then
        payload = {}
    end

    if type(payload.cash) == 'number' then
        d.cash = math.max(0, math.min(math.floor(payload.cash), Config.importCashMax or 2000000))
    end
    if type(payload.bag) == 'table' then
        for name, count in pairs(payload.bag) do
            if Items[name] and type(count) == 'number' and count > 0 then
                d.bag[name] = math.min(math.floor(count), 999)
            end
        end
    end
    if type(payload.owned) == 'table' then
        for _, car in ipairs(payload.owned) do
            -- a car is kept even if it is not in data/vehicles.lua (an older or custom car).
            -- the only thing checked is that the model name looks like a model name.
            if type(car) == 'table' and type(car.model) == 'string' and car.model:match('^[%w_]+$') and #car.model <= 32 then
                local known = Vehicles[car.model]
                local made = newCar(d, car.model,
                    (type(car.name) == 'string' and car.name) or (known and known.name) or car.model,
                    (type(car.price) == 'number' and car.price) or (known and known.price) or 0)
                if type(car.plate) == 'string' and #car.plate <= 8 then
                    made.plate = car.plate
                end
                if type(car.primary) == 'number' then made.primary = car.primary end
                if type(car.secondary) == 'number' then made.secondary = car.secondary end
            end
        end
    end
    if type(payload.jobrep) == 'table' then
        for id, points in pairs(payload.jobrep) do
            if Jobs[id] and type(points) == 'number' then
                d.jobrep[id] = math.max(0, math.min(math.floor(points), 1000000))
            end
        end
    end

    d.imported = true
    FrameOS.markDirty(source)
    FrameOS.log('import', source, 'cash ' .. d.cash .. ', ' .. #d.owned .. ' cars')
    FrameOS.push(source)
    return { ok = true }
end, { every = 1000 })

-- ---------------------------------------------------------------- shops

FrameOS.onAsk('buyItem', function(source, shopId, itemName, claimedStock)
    local d = data(source)
    local shop, why = findShop(source, shopId, 'items', claimedStock)
    if not shop then
        return no(why)
    end
    local item = type(itemName) == 'string' and Items[itemName]
    local price = item and shop.type == 'items' and stockPrice(shop.stock, itemName)
    if not price then
        return no('They do not sell that')
    end
    -- check the bag has room BEFORE taking money (weapons and ammo don't go in the bag)
    if not (item.weapon or item.ammoFor) and FrameOS.weightOf(d.bag) + (item.weight or 0) > Config.bagWeight + 0.0001 then
        return no('Your bag is too heavy')
    end
    if not FrameOS.takeCash(source, price, 'bought ' .. itemName .. ' at ' .. tostring(shopId)) then
        return no('Not enough cash')
    end

    -- things that end up in the bag are recorded here. weapons and ammo are
    -- handled on your screen (they are game objects), the server only takes the money.
    local kind = 'bag'
    if item.weapon then
        kind = 'weapon'
    elseif item.ammoFor then
        kind = 'ammo'
    else
        d.bag[itemName] = (d.bag[itemName] or 0) + 1
        FrameOS.markDirty(source)
        FrameOS.push(source)
    end
    return { ok = true, kind = kind, name = itemName }
end, { every = 150 })

FrameOS.onAsk('buyVehicle', function(source, shopId, model, claimedStock)
    local d = data(source)
    local shop, why = findShop(source, shopId, 'vehicles', claimedStock)
    if not shop then
        return no(why)
    end
    local price = type(model) == 'string' and shop.type == 'vehicles' and stockPrice(shop.stock, model, true)
    if not price then
        return no('They do not sell that')
    end
    if not FrameOS.takeCash(source, price, 'bought car ' .. model) then
        return no('Not enough cash')
    end
    local car = newCar(d, model, Vehicles[model].name, price)
    FrameOS.markDirty(source)
    FrameOS.log('car', source, 'bought ' .. model .. ' plate ' .. car.plate)
    FrameOS.push(source)
    return { ok = true, car = car }
end, { every = 500 })

FrameOS.onAsk('sellVehicle', function(source, carId)
    local d = data(source)
    for index, car in ipairs(d.owned) do
        if car.id == carId then
            -- never lose someone's things: the trunk and glovebox must be empty first
            local box = d.storage or {}
            if next(box['trunk:' .. car.plate] or {}) or next(box['glove:' .. car.plate] or {}) then
                return no('Empty the trunk and glovebox first')
            end
            table.remove(d.owned, index)
            FrameOS.markDirty(source)
            FrameOS.log('car', source, 'sold ' .. car.model .. ' plate ' .. car.plate)
            FrameOS.addCash(source, math.floor(car.price / 2), 'sold ' .. car.model)
            FrameOS.push(source)
            return { ok = true, name = car.name }
        end
    end
    return no('You do not own that car')
end, { every = 500 })

-- ---------------------------------------------------------------- using items

-- the screen checks it makes sense first (health not full, in a car), then asks.
-- the server takes one from the bag and says what it does.
FrameOS.onAsk('useItem', function(source, name)
    local d = data(source)
    local item = type(name) == 'string' and Items[name]
    if not item or (d.bag[name] or 0) < 1 then
        return no('You do not have that')
    end
    if not (item.heal or item.armor or item.fix or item.food or item.drink) then
        return no('That has no use yet')
    end
    -- food and drink are refused when they would be wasted (not hungry, not thirsty)
    local wasted = FrameOS.needsFull(d, item)
    if wasted then
        return no(wasted)
    end
    d.bag[name] = d.bag[name] - 1
    if d.bag[name] <= 0 then
        d.bag[name] = nil
    end
    FrameOS.needsEat(d, item)
    FrameOS.markDirty(source)
    FrameOS.push(source)
    return { ok = true, label = item.label, heal = item.heal, armor = item.armor, fix = item.fix,
        food = item.food, drink = item.drink }
end, { every = 300 })

-- ---------------------------------------------------------------- pickups and the hospital

local cashTaken = {}   -- "source:pickup" -> when it was last taken

-- cash pickups come from Config.pickups (the number is its position in that list).
-- cash pickups you made in game only work for admins in test mode.
FrameOS.onAsk('pickupCash', function(source, key)
    if type(key) ~= 'string' then
        return no('bad pickup')
    end
    local index = tonumber(key:sub(2))
    local spot = key:sub(1, 1) == 'c' and index and Config.pickups[index]
    if spot then
        if spot.kind ~= 'cash' or not near(source, spot.x, spot.y, spot.z, 6.0) then
            return no('Too far from the pickup')
        end
    elseif not (Config.testCommands and FrameOS.isAdmin(source)) then
        return no('Unknown pickup')
    end
    local now = GetGameTimer()
    local stamp = source .. ':' .. key
    if cashTaken[stamp] and now - cashTaken[stamp] < Config.pickupCashRespawn then
        return no('Already taken')
    end
    cashTaken[stamp] = now
    FrameOS.addCash(source, Config.pickupCash, 'cash pickup ' .. key)
    return { ok = true }
end, { every = 500 })

AddEventHandler('playerDropped', function()
    local source = source
    for stamp in pairs(cashTaken) do
        if stamp:match('^' .. source .. ':') then
            cashTaken[stamp] = nil
        end
    end
end)

-- the screen asks once when you wake up. the amount comes from the config, and it
-- never takes more than you have.
FrameOS.onAsk('hospitalBill', function(source)
    local d = data(source)
    local bill = math.min(Config.hospitalBill, d.cash)
    if bill > 0 then
        FrameOS.takeCash(source, bill, 'hospital bill')
    end
    for _, hook in ipairs(FrameOS.respawnHooks) do
        hook(source, d)
    end
    FrameOS.markDirty(source)
    FrameOS.push(source)
    return { ok = true, bill = bill }
end, { every = 10000 })

-- ---------------------------------------------------------------- jobs

local hourly = {}   -- license id -> { since, total } what jobs paid this player in the last hour
                    -- (by license, so leaving and rejoining does not reset the cap)

local function rankBonus(job)
    local best = 1.0
    for _, rank in ipairs(job.ranks or JobRanks) do
        best = math.max(best, rank.bonus)
    end
    return best
end

local function repLimit(job)
    return math.max(job.repPerPay or 0, job.repProblem or 0, job.repRival or 0)
end

local function addRep(d, id, points)
    d.jobrep[id] = math.max(0, (d.jobrep[id] or 0) + points)
end

-- pay for working. checked against the job's own data: the most one payout can ever be
-- is the top of its pay range with the best rank bonus plus the streak cap, payouts have
-- to be at least 8 seconds apart, and no player can earn more than Config.jobHourlyCap
-- an hour from jobs.
FrameOS.onAsk('jobPay', function(source, id, amount, points)
    local d = data(source)
    local job = type(id) == 'string' and Jobs[id]
    amount = math.floor(tonumber(amount) or 0)
    points = math.floor(tonumber(points) or 0)
    if not job or amount <= 0 then
        return no('bad payout')
    end
    local most = math.floor(job.pay.max * rankBonus(job)) + (job.streakCap or 0) + 5
    if amount > most or points > (job.repPerPay or 0) or points < 0 then
        FrameOS.log('refused', source, 'job payout out of range: ' .. id .. ' ' .. amount .. ' / ' .. points)
        return no('That payout was refused')
    end

    local now = GetGameTimer()
    local who = FrameOS.idOf(source)
    local bucket = hourly[who]
    if not bucket or now - bucket.since > 3600000 then
        bucket = { since = now, total = 0 }
        hourly[who] = bucket
    end
    if bucket.total + amount > (Config.jobHourlyCap or 30000) then
        FrameOS.log('refused', source, 'hourly job cap reached')
        return no('You have earned enough from jobs for now')
    end
    bucket.total = bucket.total + amount

    addRep(d, id, points)
    FrameOS.addCash(source, amount, 'job ' .. id)
    return { ok = true, rep = d.jobrep[id] }
end, { every = 8000 })

-- reputation only (winning or failing an encounter), no money
FrameOS.onAsk('jobRep', function(source, id, points)
    local d = data(source)
    local job = type(id) == 'string' and Jobs[id]
    points = math.floor(tonumber(points) or 0)
    if not job or points > repLimit(job) or points < -(job.repFail or 0) then
        return no('That was refused')
    end
    addRep(d, id, points)
    FrameOS.markDirty(source)
    FrameOS.push(source)
    return { ok = true, rep = d.jobrep[id] }
end, { every = 400 })

-- ---------------------------------------------------------------- bank and ATMs

-- deposit or withdraw. kind is 'bank' (you must be at a bank counter) or 'atm'.
-- the server cannot see ATM props, so an ATM is taken on trust, but the only thing it
-- can do is move YOUR money between your account and your pocket, and withdrawing is
-- capped per day (Config.atmDailyLimit). banks have no cap and are checked by position.
FrameOS.onAsk('bank', function(source, action, amount, kind)
    local d = data(source)
    amount = math.floor(tonumber(amount) or 0)
    if amount <= 0 or amount > 1000000000 then
        return no('Enter an amount')
    end
    if kind == 'bank' then
        local atBank = false
        for _, b in ipairs(Config.banks) do
            if near(source, b.x, b.y, b.z, 12.0) then
                atBank = true
                break
            end
        end
        if not atBank then
            return no('You are not at a bank')
        end
    elseif kind ~= 'atm' then
        return no('Bad request')
    end

    if action == 'deposit' then
        if d.cash < amount then
            return no('You do not have that much cash')
        end
        d.cash = d.cash - amount
        d.bank = d.bank + amount
    elseif action == 'withdraw' then
        if d.bank < amount then
            return no('Not enough in your account')
        end
        if kind == 'atm' then
            local left = atmLeft(d)
            if amount > left then
                return no('ATM limit left today: $' .. left)
            end
            if d.atmDay ~= os.date('%Y%m%d') then
                d.atmDay = os.date('%Y%m%d')
                d.atmOut = 0
            end
            d.atmOut = d.atmOut + amount
        end
        d.bank = d.bank - amount
        d.cash = d.cash + amount
    else
        return no('Bad request')
    end

    FrameOS.markDirty(source)
    FrameOS.log('bank', source, action .. ' ' .. amount .. ' at ' .. kind .. ' (cash ' .. d.cash .. ', bank ' .. d.bank .. ')')
    FrameOS.push(source)
    return { ok = true }
end, { every = 300 })

-- ---------------------------------------------------------------- admin test commands

-- /givecash, /setcash and /giveitem. admins only, and only while Config.testCommands is on.
FrameOS.onAsk('admin', function(source, action, a, b)
    if not (Config.testCommands and FrameOS.isAdmin(source)) then
        FrameOS.log('refused', source, 'admin request without permission: ' .. tostring(action))
        return no('Admins only')
    end
    local d = data(source)
    a = tonumber(a) or a
    if action == 'givecash' and type(a) == 'number' then
        FrameOS.addCash(source, a, 'admin givecash')
    elseif action == 'setcash' and type(a) == 'number' then
        d.cash = math.max(0, math.floor(a))
        FrameOS.markDirty(source)
        FrameOS.log('cash', source, 'admin setcash ' .. d.cash)
        FrameOS.push(source)
    elseif action == 'setbank' and type(a) == 'number' then
        d.bank = math.max(0, math.floor(a))
        FrameOS.markDirty(source)
        FrameOS.log('bank', source, 'admin setbank ' .. d.bank)
        FrameOS.push(source)
    elseif action == 'givecar' and type(a) == 'string' and a:match('^[%w_]+$') and #a <= 32 then
        local known = Vehicles[a]
        local car = newCar(d, a, (known and known.name) or a, (known and known.price) or tonumber(b) or 0)
        FrameOS.markDirty(source)
        FrameOS.log('car', source, 'admin givecar ' .. a .. ' plate ' .. car.plate)
        FrameOS.push(source)
    elseif action == 'setneeds' and type(a) == 'number' and type(tonumber(b)) == 'number' then
        d.needs.hunger = math.max(0, math.min(100, a))
        d.needs.thirst = math.max(0, math.min(100, tonumber(b)))
        FrameOS.markDirty(source)
        FrameOS.log('item', source, 'admin setneeds ' .. d.needs.hunger .. ' ' .. d.needs.thirst)
        FrameOS.push(source)
    elseif action == 'giveitem' and Items[a] then
        d.bag[a] = (d.bag[a] or 0) + (math.floor(tonumber(b) or 1))
        FrameOS.markDirty(source)
        FrameOS.log('item', source, 'admin giveitem ' .. a)
        FrameOS.push(source)
    else
        return no('Bad admin request')
    end
    return { ok = true }
end, { every = 200 })
