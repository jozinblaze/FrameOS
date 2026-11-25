-- inventory: a simple bag. it just counts how many of each item you have.
-- no slots and no weight yet, that can come later.
-- /inv         shows what's in your bag
-- /use <item>  uses one (example: /use bandage)
-- the shops use these two:
--   FrameOS.canGive(name)       true if you can receive this item right now
--   FrameOS.giveItem(name, n)   gives it to you
-- items are described in data/items.lua

local bag = FrameOS.load('inventory', {})   -- item name -> how many

local function saveBag()
    FrameOS.save('inventory', bag)
end

-- ammo only works if you already carry one of its weapons.
-- returns the weapon name you carry, or nil
local function weaponFor(item)
    local ped = PlayerPedId()
    for _, name in ipairs(item.ammoFor) do
        if HasPedGotWeapon(ped, joaat(name), false) then
            return name
        end
    end
    return nil
end

function FrameOS.canGive(name)
    local item = Items[name]
    if not item then
        return false
    end
    if item.ammoFor and not weaponFor(item) then
        FrameOS.notify('You need a gun that takes this first')
        return false
    end
    return true
end

function FrameOS.giveItem(name, count)
    local item = Items[name]
    if not item then
        return false
    end
    count = count or 1
    local ped = PlayerPedId()

    if item.weapon then
        -- weapons go straight to your hands
        GiveWeaponToPed(ped, joaat(item.weapon), item.ammo or 0, false, false)
    elseif item.ammoFor then
        local weapon = weaponFor(item)
        if not weapon then
            return false
        end
        AddAmmoToPed(ped, joaat(weapon), item.ammo)
    else
        -- everything else goes in the bag
        bag[name] = (bag[name] or 0) + count
        saveBag()
    end

    FrameOS.notify('Got ' .. item.label)
    return true
end

local function useItem(name)
    local item = Items[name]
    if not item then
        FrameOS.notify('No item called ' .. name)
        return
    end
    if (bag[name] or 0) < 1 then
        FrameOS.notify('You have no ' .. item.label)
        return
    end

    local ped = PlayerPedId()
    local used = false

    if item.heal then
        local max = GetEntityMaxHealth(ped)
        local health = GetEntityHealth(ped)
        if health >= max then
            FrameOS.notify('Your health is already full')
            return
        end
        SetEntityHealth(ped, math.min(max, health + item.heal))
        used = true
    end

    if item.armor then
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + item.armor))
        used = true
    end

    if item.fix then
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 then
            FrameOS.notify('Get in the car first')
            return
        end
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
        used = true
    end

    if not used then
        FrameOS.notify(item.label .. ' has no use yet')
        return
    end

    -- one is used up
    bag[name] = bag[name] - 1
    if bag[name] <= 0 then
        bag[name] = nil
    end
    saveBag()
    FrameOS.notify('Used ' .. item.label)
end

FrameOS.command('inv', 'shows what is in your bag', function()
    local lines = {}
    for name, count in pairs(bag) do
        table.insert(lines, Items[name].label .. ' x' .. count)
        print('[bag] ' .. name .. ' x' .. count)
    end
    if #lines == 0 then
        FrameOS.notify('Your bag is empty')
    else
        FrameOS.notify('Bag: ' .. table.concat(lines, ', '))
    end
end)

FrameOS.command('use', 'uses an item from your bag, example: /use bandage', function(source, args)
    if not args[1] then
        FrameOS.notify('Usage: /use <item>  (see /inv)')
        return
    end
    useItem(string.lower(args[1]))
end)

-- these two are for testing. Config.testCommands = false turns them off.
if Config.testCommands then
    FrameOS.testCommand('giveitem', 'gives you an item for free, example: /giveitem bandage 3', function(source, args)
        local name = args[1] and string.lower(args[1])
        if not name or not Items[name] then
            FrameOS.notify('Usage: /giveitem <item> [count]  (see /items)')
            return
        end
        FrameOS.giveItem(name, tonumber(args[2]) or 1)
    end)

    FrameOS.testCommand('items', 'prints every item name in the F8 console', function()
        for name, item in pairs(Items) do
            print(name .. ' (' .. item.label .. ')')
        end
        FrameOS.notify('Item names printed in the F8 console')
    end)
end
