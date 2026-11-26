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
