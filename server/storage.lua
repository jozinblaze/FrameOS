-- storage: containers. a container is a list of "item name -> how many" kept in your save file
-- under d.storage[id]. the id says what it is:
--     trunk:<plate>   a car's trunk       glove:<plate>   a car's glovebox
--     stash:<name>    a safehouse stash
-- your bag (d.bag) works the same way, so moving things is just taking from one list and
-- adding to the other, after the server checked who you are, where you are and the weight.
-- sizes are in data/storage.lua. nothing is ever deleted or filtered on load, an item that
-- no longer exists in data/items.lua just stays there with no weight.

local function data(source)
    return FrameOS.getPlayer(source)
end

local function no(why)
    return { ok = false, why = why }
end

local function near(source, x, y, z, range)
    local ped = GetPlayerPed(source)
    if not ped or ped == 0 then
        return false
    end
    return #(GetEntityCoords(ped) - vector3(x, y, z)) <= range
end

-- works out which container a request means. returns id, size, label, or nil and a reason.
-- cars: you must own the plate. stashes: a safehouse from the config and you must be there.
-- a safehouse you built in game only works for admins while Config.testCommands is on.
local function resolve(source, d, kind, ref)
    if type(ref) ~= 'string' or #ref > 40 then
        return nil, 'Bad request'
    end
    if kind == 'trunk' or kind == 'glove' then
        local car = nil
        for _, owned in ipairs(d.owned) do
            if owned.plate == ref then
                car = owned
                break
            end
        end
        if not car then
            return nil, 'That is not your car'
        end
        local size = Config.gloveboxWeight
        local label = (car.name or car.model) .. ' glovebox'
        if kind == 'trunk' then
            size = Config.trunkCapacity(car.model)
            label = (car.name or car.model) .. ' trunk'
        end
        if size <= 0 then
            return nil, 'This vehicle has no storage'
        end
        return kind .. ':' .. ref, size, label
    elseif kind == 'stash' then
        local house = Config.safehouses[ref]
        if house then
            if not near(source, house.x, house.y, house.z, 8.0) then
                return nil, 'You are too far from the stash'
            end
        elseif not (Config.testCommands and FrameOS.isAdmin(source)) then
            return nil, 'Unknown safehouse'
        end
        return 'stash:' .. ref, Config.stashWeight, ref .. ' stash'
    end
    return nil, 'Bad request'
end

local function box(d, id)
    d.storage = d.storage or {}
    d.storage[id] = d.storage[id] or {}
    return d.storage[id]
end

local function view(d, id, size, label)
    local items = {}
    for name, count in pairs(box(d, id)) do
        items[name] = count
    end
    return { ok = true, label = label, size = size, items = items, weight = FrameOS.weightOf(items) }
end

FrameOS.onAsk('storageOpen', function(source, kind, ref)
    local d = data(source)
    local id, size, label = resolve(source, d, kind, ref)
    if not id then
        return no(size)
    end
    return view(d, id, size, label)
end, { every = 200 })

FrameOS.onAsk('storageMove', function(source, kind, ref, direction, name, count)
    local d = data(source)
    local id, size, label = resolve(source, d, kind, ref)
    if not id then
        return no(size)
    end
    count = math.floor(tonumber(count) or 0)
    if type(name) ~= 'string' or count < 1 or count > 1000000 then
        return no('Bad request')
    end
    local contents = box(d, id)
    local weight = (Items[name] and Items[name].weight or 0) * count

    if direction == 'in' then
        if not Items[name] then
            return no('Unknown item')
        end
        if (d.bag[name] or 0) < count then
            return no('You do not have that many')
        end
        if FrameOS.weightOf(contents) + weight > size + 0.0001 then
            return no('Not enough room')
        end
        d.bag[name] = d.bag[name] - count
        if d.bag[name] <= 0 then
            d.bag[name] = nil
        end
        contents[name] = (contents[name] or 0) + count
    elseif direction == 'out' then
        if (contents[name] or 0) < count then
            return no('It does not have that many')
        end
        if FrameOS.weightOf(d.bag) + weight > FrameOS.bagLimit(d) + 0.0001 then
            return no('Your bag is too heavy')
        end
        contents[name] = contents[name] - count
        if contents[name] <= 0 then
            contents[name] = nil
        end
        d.bag[name] = (d.bag[name] or 0) + count
    else
        return no('Bad request')
    end

    FrameOS.markDirty(source)
    FrameOS.log('storage', source, direction .. ' ' .. name .. ' x' .. count .. ' (' .. id .. ')')
    FrameOS.push(source)
    return view(d, id, size, label)
end, { every = 100 })
