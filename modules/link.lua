-- link: the client's side of talking to the server.
--   local ok, answer = FrameOS.ask('name', arg1, arg2)
-- it waits for the server's reply (up to 5 seconds), so only use it inside a
-- thread or a command, never at the top of a file. ok is false if the server
-- said no or did not answer, and then answer is a short reason.
-- the server's side is FrameOS.onAsk in server/core.lua.

local waiting = {}     -- request number -> the promise we are waiting on
local counter = 0

function FrameOS.ask(name, ...)
    counter = counter + 1
    local id = counter
    local reply = promise.new()
    waiting[id] = reply

    -- if nothing comes back, stop waiting
    SetTimeout(5000, function()
        if waiting[id] then
            waiting[id] = nil
            reply:resolve({ ok = false, result = 'no answer from the server' })
        end
    end)

    TriggerServerEvent('frameos:ask', id, name, ...)
    local response = Citizen.Await(reply)
    return response.ok, response.result
end

RegisterNetEvent('frameos:answer', function(id, ok, result)
    local reply = waiting[id]
    if reply then
        waiting[id] = nil
        reply:resolve({ ok = ok, result = result })
    end
end)

-- like FrameOS.ask, but it also tells the player if the server said no.
-- returns the answer table when it worked, or nil when it did not.
function FrameOS.request(name, ...)
    local sent, answer = FrameOS.ask(name, ...)
    if not sent then
        FrameOS.notify('Server: ' .. tostring(answer))
        return nil
    end
    if type(answer) == 'table' and answer.ok == false then
        FrameOS.notify(answer.why or 'Refused')
        return nil
    end
    return answer
end

-- everything the server keeps for us (cash, bank, bag, owned cars, job rank).
-- the server sends the whole thing after every change, we only show it.
FrameOS.data = { cash = 0, bank = 0, bag = {}, owned = {}, jobrep = {} }
local dataLoaded = false

RegisterNetEvent('frameos:data', function(newData)
    local before = FrameOS.data.cash
    FrameOS.data = newData
    -- a change in cash shows as +$ or -$
    if dataLoaded and newData.cash ~= before then
        local difference = newData.cash - before
        local sign = '+'
        if difference < 0 then
            sign = '-'
        end
        FrameOS.notify(sign .. FrameOS.formatMoney(math.abs(difference)))
    end
    dataLoaded = true
end)

-- the first time on the server: copy what was saved on this computer up to it (once)
RegisterNetEvent('frameos:joined', function(imported)
    if imported then
        return
    end
    CreateThread(function()
        -- items that were renamed in v0.8.0 keep working: old name -> new name
        local renamed = {
            tosti = 'burger', water_bottle = 'water', kurkakola = 'ecola',
            twerks_candy = 'candy_bar', snikkel_candy = 'sprunk', beer = 'pisswasser',
        }
        local oldBag = FrameOS.load('inventory', nil)
        local bag = nil
        if oldBag then
            bag = {}
            for name, count in pairs(oldBag) do
                local newName = renamed[name] or name
                bag[newName] = (bag[newName] or 0) + count
            end
        end
        local payload = {
            cash = FrameOS.load('cash', nil),
            bag = bag,
            owned = FrameOS.load('owned', nil),
            jobrep = FrameOS.load('jobrep', nil),
        }
        local answer = FrameOS.request('import', payload)
        if answer then
            FrameOS.notify('Your saves were copied to the server')
        end
    end)
end)

-- say hello to the server when we start, so it loads our data
CreateThread(function()
    Wait(1000)
    TriggerServerEvent('frameos:join')
end)

-- shows your license identifier (F8 console too), to paste into Config.admins in config.lua
FrameOS.command('myid', 'shows your license id, to make yourself an admin in config.lua', function()
    local ok, id = FrameOS.ask('myid')
    if ok then
        print('[FrameOS] your id: ' .. id)
        FrameOS.notify('Your id is in the F8 console')
    else
        FrameOS.notify('Could not get your id: ' .. tostring(id))
    end
end)

-- checks the server side works: shows what the server has saved for you
FrameOS.testCommand('serverstatus', 'asks the server what it knows about you', function()
    local ok, info = FrameOS.ask('status')
    if ok then
        FrameOS.notify('Server: admin ' .. tostring(info.admin) .. ', cash ' .. info.cash .. ', bank ' .. info.bank .. ', cars ' .. info.cars)
    else
        FrameOS.notify('Server said: ' .. tostring(info))
    end
end)
