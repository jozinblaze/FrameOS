-- world: time and weather.
-- time runs on its own. Config.msPerGameMinute sets the speed (0 freezes it).
-- we keep our own clock and set the game's clock to it a few times a second,
-- the game would otherwise fight us over it.

local hour = Config.hour
local minute = Config.minute
if Config.saveClock then
    local saved = FrameOS.load('clock', nil)
    if saved then
        hour = saved.hour
        minute = saved.minute
    end
end
local weather = Config.weather
local msPerMinute = Config.msPerGameMinute
local carry = 0     -- real milliseconds that haven't turned into a game minute yet

CreateThread(function()
    local last = GetGameTimer()
    local lastSave = last
    local lastWeather = last
    while true do
        Wait(250)
        local now = GetGameTimer()

        -- move our clock forward by however much real time passed
        if msPerMinute > 0 then
            carry = carry + (now - last)
            while carry >= msPerMinute do
                carry = carry - msPerMinute
                minute = minute + 1
                if minute >= 60 then
                    minute = 0
                    hour = (hour + 1) % 24
                end
            end
        end
        last = now

        -- time of day is saved every 15 seconds or so (only the numbers that matter)
        if Config.saveClock and now - lastSave > 15000 then
            lastSave = now
            FrameOS.save('clock', { hour = hour, minute = minute })
        end

        -- weather: pick a new one from the pool every Config.weatherEvery milliseconds
        if Config.weatherCycle and now - lastWeather > Config.weatherEvery then
            lastWeather = now
            local pick = Config.weatherPool[math.random(1, #Config.weatherPool)]
            if pick then
                weather = pick
            end
        end

        -- set the game's time and weather to ours
        NetworkOverrideClockTime(hour, minute, 0)
        SetOverrideWeather(weather)
        SetWeatherTypeNowPersist(weather)
    end
end)

FrameOS.testCommand('settime', 'set the time, example: /settime 22 or /settime 22 30', function(source, args)
    local newHour = tonumber(args[1])
    local newMinute = tonumber(args[2]) or 0
    if newHour and newHour >= 0 and newHour <= 23 and newMinute >= 0 and newMinute <= 59 then
        hour = newHour
        minute = newMinute
        carry = 0
    else
        FrameOS.notify('Usage: /settime <hour 0-23> [minute]')
    end
end)

FrameOS.testCommand('timespeed', 'milliseconds per game minute, 2000 is normal, 0 freezes time', function(source, args)
    local speed = tonumber(args[1])
    if speed and speed >= 0 then
        msPerMinute = speed
        carry = 0
    else
        FrameOS.notify('Usage: /timespeed <milliseconds>  (2000 normal, 0 frozen)')
    end
end)

FrameOS.testCommand('setweather', 'set the weather, example: /setweather CLOUDS', function(source, args)
    if args[1] then
        weather = string.upper(args[1])
    end
end)
