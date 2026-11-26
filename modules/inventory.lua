-- inventory: a simple bag. it just counts how many of each item you have.
-- no slots and no weight yet, that comes with the inventory rework.
-- the SERVER keeps the bag (server/economy.lua). this file shows it and applies effects.
-- /inv         shows what's in your bag
-- /use <item>  uses one (example: /use bandage)
-- the shops use these two:
--   FrameOS.canGive(name)      true if you can receive this item right now
--   FrameOS.applyItem(name)    the part that happens on your screen after the server
--                              took the money (weapons and ammo go in your hands)
-- items are described in data/items.lua

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
    -- no paying twice for a weapon you already carry (ammo has its own item)
    if item.weapon and HasPedGotWeapon(PlayerPedId(), joaat(item.weapon), false) then
        FrameOS.notify('You already have this')
        return false
    end
    return true
end

-- called after the server said the purchase went through
function FrameOS.applyItem(name)
    local item = Items[name]
    if not item then
        return
    end
    local ped = PlayerPedId()
    if item.weapon then
        -- weapons go straight to your hands
        GiveWeaponToPed(ped, joaat(item.weapon), item.ammo or 0, false, false)
    elseif item.ammoFor then
        local weapon = weaponFor(item)
        if weapon then
            AddAmmoToPed(ped, joaat(weapon), item.ammo)
        end
    end
    -- everything else is in the bag already, the server put it there
    FrameOS.notify('Got ' .. item.label)
end

local function useItem(name)
    local item = Items[name]
    if not item then
        FrameOS.notify('No item called ' .. name)
        return
    end
    if (FrameOS.data.bag[name] or 0) < 1 then
        FrameOS.notify('You have no ' .. item.label)
        return
    end
    if not (item.heal or item.armor or item.fix) then
        FrameOS.notify(item.label .. ' has no use yet')
        return
    end

    local ped = PlayerPedId()

    -- check it makes sense BEFORE asking the server to use one up
    if item.heal and not item.armor and not item.fix then
        if GetEntityHealth(ped) >= GetEntityMaxHealth(ped) then
            FrameOS.notify('Your health is already full')
            return
        end
    end
    local vehicle = GetVehiclePedIsIn(ped, false)
    if item.fix and vehicle == 0 then
        FrameOS.notify('Get in the car first')
        return
    end

    -- the server takes one from the bag, then we apply the effect
    local answer = FrameOS.request('useItem', name)
    if not answer then
        return
    end
    if answer.heal then
        local max = GetEntityMaxHealth(ped)
        SetEntityHealth(ped, math.min(max, GetEntityHealth(ped) + answer.heal))
    end
    if answer.armor then
        SetPedArmour(ped, math.min(100, GetPedArmour(ped) + answer.armor))
    end
    if answer.fix and vehicle ~= 0 then
        SetVehicleFixed(vehicle)
        SetVehicleDeformationFixed(vehicle)
    end
    FrameOS.notify('Used ' .. item.label)
end

FrameOS.command('inv', 'shows what is in your bag', function()
    local lines = {}
    for name, count in pairs(FrameOS.data.bag) do
        -- an item that no longer exists in data/items.lua is skipped, not a crash
        if Items[name] then
            table.insert(lines, Items[name].label .. ' x' .. count)
            print('[bag] ' .. name .. ' x' .. count)
        end
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
FrameOS.testCommand('giveitem', 'gives you an item for free (admins), example: /giveitem bandage 3', function(source, args)
    local name = args[1] and string.lower(args[1])
    if not name or not Items[name] then
        FrameOS.notify('Usage: /giveitem <item> [count]  (see /items)')
        return
    end
    local item = Items[name]
    if item.weapon or item.ammoFor then
        FrameOS.applyItem(name)   -- weapons and ammo are not in the bag
    else
        FrameOS.request('admin', 'giveitem', name, tonumber(args[2]) or 1)
    end
end)

FrameOS.testCommand('items', 'prints every item name in the F8 console', function()
    for name, item in pairs(Items) do
        print(name .. ' (' .. item.label .. ')')
    end
    FrameOS.notify('Item names printed in the F8 console')
end)
