-- bank: bank counters and ATMs. walk into a bank's circle (or stand at an ATM) and press E.
--   Left / Right   switch between Deposit and Withdraw
--   Up / Down      choose an amount      Enter  confirm      Backspace  leave
-- where the banks are and the ATM limit are in data/banks.lua.
-- the account lives on the server (server/economy.lua, the 'bank' request).

local using = false          -- true while the menu is open
local nearBank = nil         -- the bank you are standing at (or nil)
local nearAtm = false        -- true when an ATM is within reach

-- map icons
CreateThread(function()
    for _, bank in ipairs(Config.banks) do
        local blip = FrameOS.addBlip(bank.x, bank.y, bank.z, Config.bankBlip.sprite, Config.bankBlip.color, bank.label)
        if blip then
            SetBlipScale(blip, Config.bankBlip.scale or 0.55)
        end
    end
end)

-- types a number on the game's own keyboard box. returns nil if you cancel.
local function askAmount()
    AddTextEntry('FRAMEOS_AMT', 'Amount')
    DisplayOnscreenKeyboard(1, 'FRAMEOS_AMT', '', '', '', '', '', 9)
    while UpdateOnscreenKeyboard() == 0 do
        Wait(0)
        DisableAllControlActions(0)
    end
    local amount = nil
    if UpdateOnscreenKeyboard() == 1 then
        amount = tonumber(GetOnscreenKeyboardResult())
    end
    Wait(250)   -- so the Enter that closed the box doesn't also count in the menu
    return amount
end

local function openMenu(kind, title)
    using = true
    local ped = PlayerPedId()
    FreezeEntityPosition(ped, true)

    local tab = 'deposit'
    local index = 1
    -- the rows are the quick amounts, then "All", then "Custom"
    local rows = #Config.bankAmounts + 2

    while using do
        Wait(0)
        if IsEntityDead(ped) then   -- dying closes the menu, or you'd respawn frozen
            using = false
        end

        local limitText = ''
        if kind == 'atm' then
            limitText = '     ATM limit left today ' .. FrameOS.formatMoney(FrameOS.data.atmLeft or 0)
        end
        FrameOS.drawText(title, 0.5, 0.17, 0.7, true)
        FrameOS.drawText('Cash ' .. FrameOS.formatMoney(FrameOS.getCash()) ..
            '     Account ' .. FrameOS.formatMoney(FrameOS.data.bank or 0) .. limitText, 0.5, 0.215, 0.4, true)

        local tabs = '  Deposit  '
        local tabs2 = '  Withdraw  '
        FrameOS.drawText(tab == 'deposit' and ('[' .. tabs .. ']') or tabs, 0.44, 0.255, 0.5, true,
            tab == 'deposit' and { 255, 220, 80 } or { 255, 255, 255 })
        FrameOS.drawText(tab == 'withdraw' and ('[' .. tabs2 .. ']') or tabs2, 0.56, 0.255, 0.5, true,
            tab == 'withdraw' and { 255, 220, 80 } or { 255, 255, 255 })

        for row = 1, rows do
            local text
            if row <= #Config.bankAmounts then
                text = FrameOS.formatMoney(Config.bankAmounts[row])
            elseif row == #Config.bankAmounts + 1 then
                text = 'Everything possible'
            else
                text = 'Another amount...'
            end
            if row == index then
                FrameOS.drawText('> ' .. text .. ' <', 0.5, 0.30 + (row - 1) * 0.04, 0.5, true, { 255, 220, 80 })
            else
                FrameOS.drawText(text, 0.5, 0.30 + (row - 1) * 0.04, 0.45, true)
            end
        end
        FrameOS.drawText('Left / Right switch     Up / Down choose     Enter confirm     Backspace leave',
            0.5, 0.30 + rows * 0.04 + 0.02, 0.4, true)

        if IsControlJustPressed(0, 174) or IsControlJustPressed(0, 175) then      -- left / right
            tab = tab == 'deposit' and 'withdraw' or 'deposit'
        elseif IsControlJustPressed(0, 172) then                                  -- up
            index = index - 1
            if index < 1 then
                index = rows
            end
        elseif IsControlJustPressed(0, 173) then                                  -- down
            index = index % rows + 1
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then   -- enter
            local amount
            if index <= #Config.bankAmounts then
                amount = Config.bankAmounts[index]
            elseif index == #Config.bankAmounts + 1 then
                if tab == 'deposit' then
                    amount = FrameOS.getCash()
                else
                    amount = FrameOS.data.bank or 0
                    if kind == 'atm' then
                        amount = math.min(amount, FrameOS.data.atmLeft or 0)
                    end
                end
            else
                amount = askAmount()
            end
            amount = math.floor(tonumber(amount) or 0)
            if amount > 0 then
                local answer = FrameOS.request('bank', tab, amount, kind)
                if answer then
                    local word = tab == 'deposit' and 'Deposited ' or 'Withdrew '
                    FrameOS.notify(word .. FrameOS.formatMoney(amount))
                end
            elseif index > #Config.bankAmounts then
                FrameOS.notify('Nothing to move')
            end
        elseif IsControlJustPressed(0, 177) then                                  -- backspace
            using = false
        end
    end

    FreezeEntityPosition(PlayerPedId(), false)
end

-- looks for a bank counter or an ATM near you twice a second
CreateThread(function()
    local models = {}
    for _, name in ipairs(Config.atmModels) do
        table.insert(models, joaat(name))
    end
    while true do
        Wait(500)
        nearBank, nearAtm = nil, false
        local ped = PlayerPedId()
        if not using and not IsPedInAnyVehicle(ped, false) and not IsEntityDead(ped) then
            local coords = GetEntityCoords(ped)
            for _, bank in ipairs(Config.banks) do
                if #(coords - vector3(bank.x, bank.y, bank.z)) < 2.5 then
                    nearBank = bank
                    break
                end
            end
            if not nearBank then
                for _, model in ipairs(models) do
                    if GetClosestObjectOfType(coords.x, coords.y, coords.z, 1.6, model, false, false, false) ~= 0 then
                        nearAtm = true
                        break
                    end
                end
            end
        end
    end
end)

-- the prompt and the E key. nothing near: check twice a second.
CreateThread(function()
    while true do
        local sleep = 250
        if not using and (nearBank or nearAtm) then
            sleep = 0
            if nearBank then
                FrameOS.help('Press ~INPUT_CONTEXT~ to use the bank')
            else
                FrameOS.help('Press ~INPUT_CONTEXT~ to use the ATM')
            end
            if IsControlJustPressed(0, 38) then   -- 38 is the E key
                if nearBank then
                    openMenu('bank', nearBank.label)
                else
                    openMenu('atm', 'ATM')
                end
            end
        end
        Wait(sleep)
    end
end)

-- build tool, test only: /setbank <amount> sets your account (admins)
FrameOS.testCommand('setbank', 'sets your bank account (admins), example: /setbank 50000', function(source, args)
    local amount = tonumber(args[1])
    if amount then
        FrameOS.request('admin', 'setbank', amount)
    else
        FrameOS.notify('Usage: /setbank <amount>')
    end
end)
