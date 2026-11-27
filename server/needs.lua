-- needs: hunger and thirst, kept on the server.
-- both run from 100 (full) down to 0 (empty). the server lowers them once a minute for
-- everyone who is loaded in, and food and drink items raise them. the client only shows the
-- state and applies the effects (slower health regen when low, a little damage when empty,
-- see modules/needs.lua). the numbers are in Config.needs (config.lua).
--
-- other server files use:
--   FrameOS.needsFull(d, item)    returns a reason if the item would be wasted, or nil
--   FrameOS.needsEat(d, item)     applies an item's food / drink to the player data
--   FrameOS.needsTick()           one minute of hunger and thirst for everyone (also run by the timer)
-- and it registers itself with FrameOS.onRespawn so waking up at the hospital refills a bit.

local function clamp(n)
    return math.max(0, math.min(100, n))
end

-- how full an item can still make you: true if it would raise something that is not full
local function wouldHelp(d, item)
    local needs = d.needs
    return (item.food and needs.hunger < 98) or (item.drink and needs.thirst < 98)
end

function FrameOS.needsFull(d, item)
    if not (item.food or item.drink) then
        return nil
    end
    if wouldHelp(d, item) then
        return nil
    end
    if item.food and not item.drink then
        return 'You are not hungry'
    elseif item.drink and not item.food then
        return 'You are not thirsty'
    end
    return 'You are not hungry or thirsty'
end

function FrameOS.needsEat(d, item)
    local needs = d.needs
    if item.food then
        needs.hunger = clamp(needs.hunger + item.food)
    end
    if item.drink then
        needs.thirst = clamp(needs.thirst + item.drink)
    end
end

function FrameOS.needsTick()
    local settings = Config.needs
    FrameOS.eachPlayer(function(source, d)
        d.needs = d.needs or { hunger = 100, thirst = 100 }
        d.needs.hunger = clamp((d.needs.hunger or 100) - settings.hungerPerMinute)
        d.needs.thirst = clamp((d.needs.thirst or 100) - settings.thirstPerMinute)
        FrameOS.markDirty(source)
        FrameOS.push(source)
    end)
end

CreateThread(function()
    while true do
        Wait(60000)
        FrameOS.needsTick()
    end
end)

-- waking up at the hospital: you are never left starving, but you are not fully fed either
FrameOS.onRespawn(function(source, d)
    d.needs = d.needs or { hunger = 100, thirst = 100 }
    d.needs.hunger = math.max(d.needs.hunger, Config.needs.afterDeath)
    d.needs.thirst = math.max(d.needs.thirst, Config.needs.afterDeath)
end)
