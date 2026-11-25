-- cash: a money counter in the top right.
-- other modules use these three:
--   FrameOS.getCash()        how much you have
--   FrameOS.addCash(amount)  gives you money
--   FrameOS.takeCash(amount) takes money, returns false if you can't afford it

local cash = FrameOS.load('cash', Config.startCash)

-- turns 1250 into $1,250
local function formatMoney(amount)
    local text = tostring(math.floor(amount))
    -- put a comma after every group of three digits, counting from the right
    text = text:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    -- if that left a comma at the very start, remove it
    text = text:gsub('^,', '')
    return '$' .. text
end

-- other modules use this to show prices
FrameOS.formatMoney = formatMoney

function FrameOS.getCash()
    return cash
end

function FrameOS.addCash(amount)
    cash = cash + amount
    FrameOS.save('cash', cash)
    FrameOS.notify('+' .. formatMoney(amount))
end

function FrameOS.takeCash(amount)
    if cash < amount then
        FrameOS.notify('Not enough cash')
        return false
    end
    cash = cash - amount
    FrameOS.save('cash', cash)
    FrameOS.notify('-' .. formatMoney(amount))
    return true
end

-- draws the counter every frame
CreateThread(function()
    while true do
        Wait(0)
        SetTextFont(4)
        SetTextScale(0.6, 0.6)
        SetTextColour(120, 220, 120, 255)
        SetTextOutline()
        SetTextRightJustify(true)
        SetTextWrap(0.0, 0.985)
        BeginTextCommandDisplayText('STRING')
        AddTextComponentSubstringPlayerName(formatMoney(cash))
        EndTextCommandDisplayText(0.0, 0.03)
    end
end)

-- these two are for testing. Config.testCommands = false turns them off.
if Config.testCommands then
    FrameOS.testCommand('givecash', 'adds money, example: /givecash 1000', function(source, args)
        local amount = tonumber(args[1])
        if amount then
            FrameOS.addCash(amount)
        else
            FrameOS.notify('Usage: /givecash <amount>')
        end
    end)

    FrameOS.testCommand('setcash', 'sets your money, example: /setcash 0', function(source, args)
        local amount = tonumber(args[1])
        if amount then
            cash = amount
            FrameOS.save('cash', cash)
        else
            FrameOS.notify('Usage: /setcash <amount>')
        end
    end)
end
