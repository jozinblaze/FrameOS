-- needs: shows and applies hunger and thirst. the server owns the numbers (server/needs.lua),
-- this only reads FrameOS.data.needs.
--   well fed      health comes back at the normal speed
--   getting low   health comes back slower
--   very low      health does not come back by itself
--   empty         you slowly lose health, but never enough to kill you (Config.needs.floor)
-- nothing is drawn while you are fine. only a small line appears when one is low.
-- /needs shows the numbers. food and drink items have a food = or drink = number (data/items.lua).

local settings = Config.needs
local warned = { hunger = false, thirst = false }

local function level()
    local needs = FrameOS.data.needs or { hunger = 100, thirst = 100 }
    return needs.hunger, needs.thirst
end

-- the line shown while low, or nil
local function statusLine()
    local hunger, thirst = level()
    local parts = {}
    if hunger <= 0 then
        table.insert(parts, 'Starving')
    elseif hunger <= settings.warnAt then
        table.insert(parts, 'Hungry')
    end
    if thirst <= 0 then
        table.insert(parts, 'Dehydrated')
    elseif thirst <= settings.warnAt then
        table.insert(parts, 'Thirsty')
    end
    if #parts == 0 then
        return nil
    end
    return table.concat(parts, ', ')
end

-- tells you once when you cross the line, and again once you have eaten and dropped back
local function warn(name, value, low, empty)
    if value <= 0 then
        if warned[name] ~= 'empty' then
            warned[name] = 'empty'
            FrameOS.notify(empty)
        end
    elseif value <= settings.warnAt then
        if warned[name] == false then
            warned[name] = 'low'
            FrameOS.notify(low)
        end
    elseif value > settings.warnAt + 5 then
        warned[name] = false
    end
end

-- health regen speed and the damage from being empty. checked every 2 seconds.
CreateThread(function()
    local sinceDamage = 0
    while true do
        Wait(2000)
        local hunger, thirst = level()
        local worst = math.min(hunger, thirst)

        warn('hunger', hunger, 'You are getting hungry', 'You are starving')
        warn('thirst', thirst, 'You are getting thirsty', 'You are dehydrated')

        local multiplier = settings.regenFed
        if worst <= settings.regenStopAt then
            multiplier = 0.0
        elseif worst <= settings.regenSlowAt then
            multiplier = settings.regenSlow
        end
        SetPlayerHealthRechargeMultiplier(PlayerId(), multiplier)

        local ped = PlayerPedId()
        if worst <= 0 and not IsEntityDead(ped) then
            sinceDamage = sinceDamage + 2000
            if sinceDamage >= settings.damageEvery then
                sinceDamage = 0
                local health = GetEntityHealth(ped)
                if health > settings.floor then
                    SetEntityHealth(ped, health - settings.damage)
                end
            end
        else
            sinceDamage = 0
        end
    end
end)

-- the small line under the job text, only while something is low
CreateThread(function()
    while true do
        local line = statusLine()
        if line then
            -- right aligned under the cash counter and the job line, same style as them
            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(255, 150, 60, 230)
            SetTextOutline()
            SetTextRightJustify(true)
            SetTextWrap(0.0, 0.985)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(line)
            EndTextCommandDisplayText(0.0, 0.11)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

-- an upper-body animation, so you can eat or drink while walking.
-- loops for a moment then stops. nothing happens in a vehicle or if the animation won't load.
local function playUse(kind)
    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) or IsEntityDead(ped) then
        return
    end
    local dict, anim = 'mp_player_inteat@burger', 'mp_player_int_eat_burger'
    if kind == 'drink' then
        dict, anim = 'mp_player_intdrink', 'loop_bottle'
    end
    RequestAnimDict(dict)
    local waited = 0
    while not HasAnimDictLoaded(dict) and waited < 2000 do
        Wait(10)
        waited = waited + 10
    end
    if not HasAnimDictLoaded(dict) then
        return
    end
    TaskPlayAnim(ped, dict, anim, 4.0, -4.0, settings.useTime, 49, 0, false, false, false)
    Wait(settings.useTime)
    StopAnimTask(ped, dict, anim, 2.0)
    RemoveAnimDict(dict)
end

-- the item module calls this after the server took the item and said what it fed
function FrameOS.playUseAnimation(answer)
    if answer.food or answer.drink then
        CreateThread(function()
            playUse(answer.food and 'eat' or 'drink')
        end)
    end
end

-- uses the first food or drink in your bag that would help right now.
-- kind is 'food' or 'drink'. the best fit is the one that fills the most.
local function useBest(kind)
    local best, bestAmount = nil, 0
    for name, count in pairs(FrameOS.data.bag) do
        local item = Items[name]
        local amount = item and item[kind]
        if amount and count > 0 and amount > bestAmount then
            best, bestAmount = name, amount
        end
    end
    if not best then
        FrameOS.notify(kind == 'food' and 'You have nothing to eat' or 'You have nothing to drink')
        return
    end
    FrameOS.useItem(best)
end

FrameOS.command('eat', 'eats the food in your bag that fills you most', function()
    useBest('food')
end)

FrameOS.command('drink', 'drinks the drink in your bag that quenches you most', function()
    useBest('drink')
end)

FrameOS.command('needs', 'shows how hungry and thirsty you are', function()
    local hunger, thirst = level()
    FrameOS.notify(string.format('Hunger %d%%, thirst %d%%', math.floor(hunger + 0.5), math.floor(thirst + 0.5)))
end)

FrameOS.testCommand('setneeds', 'sets hunger and thirst (admins), example: /setneeds 20 5', function(source, args)
    local hunger, thirst = tonumber(args[1]), tonumber(args[2] or args[1])
    if hunger and thirst then
        FrameOS.request('admin', 'setneeds', hunger, thirst)
    else
        FrameOS.notify('Usage: /setneeds <hunger 0-100> [thirst 0-100]')
    end
end)
