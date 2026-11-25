-- world: time and weather.
-- time runs on its own. Config.msPerGameMinute sets the speed (0 freezes it).
-- we keep our own clock and set the game's clock to it a few times a second,
-- the game would otherwise fight us over it.

local hour = Config.hour
local minute = Config.minute
local weather = Config.weather
local msPerMinute = Config.msPerGameMinute
local carry = 0     -- real milliseconds that haven't turned into a game minute yet

CreateThread(function()
    local last = GetGameTimer()
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
