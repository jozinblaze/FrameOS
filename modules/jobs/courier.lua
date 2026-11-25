-- courier: the simplest job. you are working while you drive and keep moving.
-- sitting still or walking around counts as idle, and the payout timer pauses.
-- this is the pattern every job follows: register an isActive function.
-- pay, rank and the spot are in data/jobs.lua.

FrameOS.registerJob('courier', {
    -- true = counts as working right now (checked once a second)
    isActive = function()
        local ped = PlayerPedId()
        local vehicle = GetVehiclePedIsIn(ped, false)
        if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
            return false   -- not driving
        end
        return GetEntitySpeed(vehicle) > 3.0   -- faster than a walk (meters per second)
    end,

    onStart = function()
        FrameOS.notify('Get in a car and keep driving. You are paid while you move.')
    end,
})
