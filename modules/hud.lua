-- hud: strips the default GTA V / GTA Online interface
-- and draws a small readout of our own

local radarOnFoot = Config.radarOnFoot
local showReadout = true

-- the street name and the watch check don't need to be asked for every frame.
-- they are refreshed twice a second and the readout just draws what was found.
local street = ''
local hasWatch = false

-- runs every frame, because hiding only lasts a single frame
CreateThread(function()
    while true do
        Wait(0)

        -- hide the default pieces
        for _, id in ipairs(Config.hideHud) do
            HideHudComponentThisFrame(id)
        end

        -- minimap: only in a vehicle (unless you forced it on with /radar)
        DisplayRadar(IsPedInAnyVehicle(PlayerPedId(), false) or radarOnFoot)

        -- turn off the GTA Online interaction menu (M) and the phone (up arrow)
        DisableControlAction(0, 244, true)
        DisableControlAction(0, 27, true)

        -- our own readout: street name, the time (only with a watch on)
        -- and your speed when you're in a vehicle
        if showReadout then
            local ped = PlayerPedId()
            local lines = { street }

            -- the time only shows while you wear a watch (checked in the thread below)
            if hasWatch then
                table.insert(lines, string.format('%02d:%02d', GetClockHours(), GetClockMinutes()))
            end

            -- on foot the readout sits bottom left. in a vehicle it moves
            -- to the right of the minimap and adds your speed.
            local pos = Config.readoutFoot
            local vehicle = GetVehiclePedIsIn(ped, false)
            if vehicle ~= 0 then
                pos = Config.readoutCar
                local speed = GetEntitySpeed(vehicle)   -- meters per second
                local unit = 'km/h'
                if Config.useMph then
                    speed = speed * 2.236936
                    unit = 'mph'
                else
                    speed = speed * 3.6
                end
                table.insert(lines, string.format('%d %s', math.floor(speed + 0.5), unit))
            end

            -- one line under the other
            for number, text in ipairs(lines) do
                FrameOS.drawText(text, pos.x, pos.y + (number - 1) * 0.03, 0.45)
            end
        end
    end
end)

-- refreshes the street name and the watch twice a second.
-- a prop slot with nothing worn in it reports -1.
CreateThread(function()
    while true do
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        street = GetStreetNameFromHashKey(GetStreetNameAtCoord(coords.x, coords.y, coords.z))
        hasWatch = not Config.watchRequired or GetPedPropIndex(ped, Config.watchSlot) ~= -1
        Wait(500)
    end
end)

-- the minimap draws health and armor bars under it.
-- this asks the minimap to hide them (3 = hide both).
-- to bring the bars back, delete this whole thread.
CreateThread(function()
    local minimap = RequestScaleformMovie('minimap')
    -- toggling the big map once makes the setting stick
    SetRadarBigmapEnabled(true, false)
    Wait(0)
    SetRadarBigmapEnabled(false, false)
    while true do
        Wait(0)
        BeginScaleformMovieMethod(minimap, 'SETUP_HEALTH_ARMOUR')
        ScaleformMovieMethodAddParamInt(3)
        EndScaleformMovieMethod()
    end
end)

FrameOS.command('hud', 'turns the street, time and speed readout on or off', function()
    showReadout = not showReadout
end)

FrameOS.command('radar', 'forces the minimap on while on foot (it always shows in vehicles)', function()
    radarOnFoot = not radarOnFoot
end)
