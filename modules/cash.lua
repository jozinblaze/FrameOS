-- cash: a money counter in the top right.
-- the server owns your money. this only shows the number it sent (FrameOS.data.cash).
-- to earn or spend, a module asks the server for something specific (buy, pickup, job pay),
-- see server/economy.lua. there is no "add cash" for the client any more.
--   FrameOS.getCash()       how much you have (as of the last thing the server sent)
--   FrameOS.formatMoney(n)  turns 1250 into $1,250

-- turns 1250 into $1,250
local function formatMoney(amount)
    local text = tostring(math.floor(amount))
    -- put a comma after every group of three digits, counting from the right
    text = text:reverse():gsub('(%d%d%d)', '%1,'):reverse()
    -- if that left a comma at the very start, remove it
    text = text:gsub('^,', '')
    return '$' .. text
end

FrameOS.formatMoney = formatMoney

function FrameOS.getCash()
    return FrameOS.data.cash
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
        AddTextComponentSubstringPlayerName(formatMoney(FrameOS.data.cash))
        EndTextCommandDisplayText(0.0, 0.03)
    end
end)

-- these two are for testing, and the server only allows admins to use them.
-- Config.testCommands = false turns them off.
FrameOS.testCommand('givecash', 'adds money (admins), example: /givecash 1000', function(source, args)
    local amount = tonumber(args[1])
    if amount then
        FrameOS.request('admin', 'givecash', amount)
    else
        FrameOS.notify('Usage: /givecash <amount>')
    end
end)

FrameOS.testCommand('setcash', 'sets your money (admins), example: /setcash 0', function(source, args)
    local amount = tonumber(args[1])
    if amount then
        FrameOS.request('admin', 'setcash', amount)
    else
        FrameOS.notify('Usage: /setcash <amount>')
    end
end)
