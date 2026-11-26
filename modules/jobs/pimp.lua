-- pimping: a job in the job engine (modules/jobs.lua). settings, pay, ranks and
-- every line of text are in data/jobs.lua under Jobs.pimp.
--
-- how a run goes. each girl is her own little machine that moves through states:
--   spawn     waiting to appear somewhere near you
--   waiting   she is out there, stop next to her to pick her up
--   boarding  she is getting in your car
--   ride      she is in your car, you are driving her to the customer (green blip)
--   working   she is with the customer, you drive around. nothing to do but wait
--   collect   she is done, stop next to her again. you get paid when she gets in
--   problem   the customer ran off without paying, go hurt him (or catch him)
--   rival     a rival gang showed up where the customer was, kill them
--   rest      she takes a break, then goes back to waiting
-- every 250 ms each girl runs one step of her state (see step() below).

local job = Jobs.pimp
local girls = {}      -- one entry per girl
local session = 0     -- goes up on every clock-in and clock-out, so old threads know to stop
local streak = 0      -- customers in a row without a failure

-- ---------------------------------------------------------------- small helpers

local function pick(list)
    return list[math.random(1, #list)]
end

local function say(girl, list)
    FrameOS.message(girl.name, job.label, pick(list))
end

-- a map blip on a ped. we make these ourselves (not FrameOS.addBlip) because
-- they are part of the job, so Config.showBlips = false must not hide them.
local function blipOn(entity, color, label)
    local blip = AddBlipForEntity(entity)
    SetBlipColour(blip, color)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
    return blip
end

local function dropBlip(blip)
    if blip and DoesBlipExist(blip) then
        RemoveBlip(blip)
    end
end

local function showBlip(blip, shown)
    if blip and DoesBlipExist(blip) then
        SetBlipAlpha(blip, shown and 255 or 0)
    end
end

-- finds a spot on foot-friendly ground, between minDist and maxDist meters from you.
-- returns nil if it can't find one (we just try again a moment later).
local function findSpot(minDist, maxDist)
    local origin = GetEntityCoords(PlayerPedId())
    for tries = 1, 100 do
        local angle = math.random() * 2 * math.pi
        local dist = minDist + math.random() * (maxDist - minDist)
        local x = origin.x + math.cos(angle) * dist
        local y = origin.y + math.sin(angle) * dist
        -- the last number is a setting for what counts as safe, we get stricter then looser
        local flag = 1
        if tries > 50 then
            flag = 16
        end
        local found, pos = GetSafeCoordForPed(x, y, origin.z, true, flag)
        if found then
            return pos
        end
        Wait(0)
    end
    return nil
end

local function makePed(modelName, pos)
    local model = joaat(modelName)
    if not IsModelInCdimage(model) then
        print('[pimp] no ped model called ' .. modelName)
        return nil
    end
    RequestModel(model)
    local waited = 0
    while not HasModelLoaded(model) and waited < 5000 do
        Wait(10)
        waited = waited + 10
    end
    if not HasModelLoaded(model) then
        return nil
    end
    local ped = CreatePed(4, model, pos.x, pos.y, pos.z, math.random(0, 359) + 0.0, true, true)
    SetModelAsNoLongerNeeded(model)
    SetEntityAsMissionEntity(ped, true, true)
    SetBlockingOfNonTemporaryEvents(ped, true)   -- they ignore what happens around them
    SetEntityMaxHealth(ped, 200)
    SetEntityHealth(ped, 200)
    return ped
end

-- lets a ped go: they walk off and the game removes them when it likes
local function release(ped)
    if ped and DoesEntityExist(ped) then
        TaskWanderStandard(ped, 10.0, 10)
        SetPedAsNoLongerNeeded(ped)
    end
end

-- the car you are driving, but only if you are stopped next to this girl
-- and the passenger seat is free
local function pickupVehicle(girl)
    local ped = PlayerPedId()
    local vehicle = GetVehiclePedIsIn(ped, false)
    if vehicle == 0 or GetPedInVehicleSeat(vehicle, -1) ~= ped then
        return nil
    end
    if GetEntitySpeed(vehicle) > 1.0 or not IsVehicleSeatFree(vehicle, 0) then
        return nil
    end
    if #(GetEntityCoords(vehicle) - GetEntityCoords(girl.ped)) > 10.0 then
        return nil
    end
    return vehicle
end

-- pay for one customer. the streak bonus grows with every customer in a row.
local function payCustomer()
    local rank = FrameOS.jobRank('pimp')
    local amount = math.floor(math.random(job.pay.min, job.pay.max) * rank.bonus)
    amount = amount + math.min(streak * job.streakBonus, job.streakCap)
    streak = streak + 1
    FrameOS.jobPay('pimp', amount, job.repPerPay)
end

-- the customer (and any rivals) are done with. the girl takes a break.
local function finishCustomer(girl)
    dropBlip(girl.cblip)
    girl.cblip = nil
    release(girl.customer)
    girl.customer = nil
    for _, rival in ipairs(girl.rivals or {}) do
        dropBlip(rival.blip)
        release(rival.ped)
    end
    girl.rivals = nil
    girl.state = 'rest'
    girl.untilTime = GetGameTimer() + math.random(20000, 60000)
end

-- ---------------------------------------------------------------- the steps

local function spawnGirl(girl)
    local pos = findSpot(80.0, job.spawnRadius)
    if not pos then
        return
    end
    girl.ped = makePed(pick(job.girlModels), pos)
    if not girl.ped then
        return
    end
    girl.blip = blipOn(girl.ped, 3, 'Girl')
    girl.state = 'waiting'
    say(girl, job.text.pickup)
end

local function startRide(girl)
    local pos = findSpot(80.0, job.spawnRadius)
    if not pos then
        return   -- not found this time, we try again on the next step
    end
    girl.customer = makePed(pick(job.customerModels), pos)
    if not girl.customer then
        return
    end
    girl.cblip = blipOn(girl.customer, 2, 'Customer')
    girl.state = 'ride'
    say(girl, job.text.customer)
end

local function startProblem(girl)
    girl.state = 'problem'
    girl.deadline = GetGameTimer() + 90000
    showBlip(girl.cblip, true)
    SetBlipColour(girl.cblip, 1)   -- red
    -- he runs from you
    TaskSmartFleePed(girl.customer, PlayerPedId(), 150.0, -1, false, false)
    say(girl, job.text.problem)
end

local function startRival(girl)
    girl.state = 'rival'
    girl.deadline = GetGameTimer() + 300000
    girl.rivalPos = GetEntityCoords(girl.customer)
    girl.rivals = {}
    girl.rivalsOut = false
    say(girl, job.text.rival)
end

-- the two rival gang members appear once you are close enough to the spot
local function spawnRivals(girl)
    for _ = 1, 2 do
        local pos = vector3(girl.rivalPos.x + math.random(-4, 4), girl.rivalPos.y + math.random(-4, 4), girl.rivalPos.z)
        local ped = makePed(pick(job.rivalModels), pos)
        if ped then
            SetPedRelationshipGroupHash(ped, joaat('HATES_PLAYER'))
            GiveWeaponToPed(ped, joaat(pick(job.rivalWeapons)), 255, false, true)
            SetPedAccuracy(ped, math.random(40, 60))
            SetPedDropsWeaponsWhenDead(ped, false)
            SetBlockingOfNonTemporaryEvents(ped, false)
            table.insert(girl.rivals, { ped = ped, blip = blipOn(ped, 1, 'Rival') })
        end
    end
    girl.rivalsOut = true
end

local function failEncounter(girl)
    say(girl, job.text.fail)
    FrameOS.jobPay('pimp', 0, -job.repFail)
    streak = 0
    finishCustomer(girl)
end

local function winEncounter(girl, rep)
    say(girl, job.text.success)
    FrameOS.jobPay('pimp', 0, rep)
    payCustomer()
    finishCustomer(girl)
end

local function step(girl)
    local now = GetGameTimer()

    -- a girl that died is replaced after a while, and it costs you your streak
    if girl.ped and IsEntityDead(girl.ped) then
        dropBlip(girl.blip)
        release(girl.ped)
        girl.ped = nil
        streak = 0
        if girl.customer then
            finishCustomer(girl)
        end
        girl.state = 'spawn'
        say(girl, job.text.lost)
        return
    end

    local state = girl.state

    if state == 'spawn' then
        spawnGirl(girl)

    elseif state == 'waiting' or state == 'collect' then
        local vehicle = pickupVehicle(girl)
        if vehicle then
            girl.vehicle = vehicle
            girl.after = state                      -- what to do once she is in the car
            girl.deadline = now + 10000
            TaskEnterVehicle(girl.ped, vehicle, 8000, 0, 1.0, 1, 0)
            girl.state = 'boarding'
        end

    elseif state == 'boarding' then
        if not DoesEntityExist(girl.vehicle) then
            girl.state = girl.after
        elseif IsPedInVehicle(girl.ped, girl.vehicle, false) then
            showBlip(girl.blip, false)
            if girl.after == 'waiting' then
                startRide(girl)            -- stays in 'boarding' until a customer was found
            else
                -- she is back in the car after working: this is the payday
                payCustomer()
                TaskLeaveVehicle(girl.ped, girl.vehicle, 0)
                finishCustomer(girl)
            end
        elseif now > girl.deadline then
            TaskWarpPedIntoVehicle(girl.ped, girl.vehicle, 0)   -- stuck? put her in the seat
            girl.deadline = now + 10000
        end

    elseif state == 'ride' then
        -- the car is gone (you swapped cars?): the customer leaves, she wants picking up
        if not DoesEntityExist(girl.vehicle) then
            finishCustomer(girl)
            girl.state = 'waiting'
            showBlip(girl.blip, true)
            return
        end
        local carPos = GetEntityCoords(girl.vehicle)
        local customerPos = GetEntityCoords(girl.customer)
        -- stopped close to the customer: she gets out and walks to him
        if #(carPos - customerPos) < 15.0 and GetEntitySpeed(girl.vehicle) < 1.0 then
            TaskLeaveVehicle(girl.ped, girl.vehicle, 0)
            girl.walkAt = now + 1500
            girl.untilTime = now + math.random(40000, 100000)
            showBlip(girl.cblip, false)
            girl.state = 'working'
            say(girl, job.text.away)
        end

    elseif state == 'working' then
        if girl.walkAt and now >= girl.walkAt then
            local at = GetEntityCoords(girl.customer)
            TaskGoToCoordAnyMeans(girl.ped, at.x, at.y, at.z, 1.0, 0, false, 786603, -1.0)
            girl.walkAt = nil
        end
        if now >= girl.untilTime then
            local roll = math.random(1, 100)
            if roll <= job.problemChance then
                startProblem(girl)
            elseif roll <= job.problemChance + job.rivalChance then
                startRival(girl)
            else
                -- all fine: he leaves, she wants picking up
                dropBlip(girl.cblip)
                girl.cblip = nil
                release(girl.customer)
                girl.state = 'collect'
                showBlip(girl.blip, true)
                say(girl, job.text.ready)
            end
        end

    elseif state == 'problem' then
        local customer = girl.customer
        local hurt = IsEntityDead(customer) or GetEntityHealth(customer) < 150
        local escaped = #(GetEntityCoords(PlayerPedId()) - GetEntityCoords(customer)) > 160.0
        if hurt then
            winEncounter(girl, job.repProblem)
        elseif escaped or now > girl.deadline then
            failEncounter(girl)
        end

    elseif state == 'rival' then
        local playerPos = GetEntityCoords(PlayerPedId())
        if not girl.rivalsOut then
            if #(playerPos - girl.rivalPos) < 250.0 then
                spawnRivals(girl)
                -- the customer is no longer needed
                dropBlip(girl.cblip)
                girl.cblip = nil
                release(girl.customer)
                girl.customer = nil
            elseif now > girl.deadline then
                failEncounter(girl)
            end
        else
            local alive = 0
            local nearest = 99999.0
            for _, rival in ipairs(girl.rivals) do
                if not IsEntityDead(rival.ped) then
                    alive = alive + 1
                    local dist = #(playerPos - GetEntityCoords(rival.ped))
                    nearest = math.min(nearest, dist)
                    -- they go for you once you are close
                    if dist < 60.0 and not rival.attacking then
                        rival.attacking = true
                        TaskCombatPed(rival.ped, PlayerPedId(), 0, 16)
                    end
                end
            end
            if alive == 0 then
                winEncounter(girl, job.repRival)
            elseif nearest > 220.0 or now > girl.deadline then
                failEncounter(girl)
            end
        end

    elseif state == 'rest' then
        if now >= girl.untilTime then
            girl.state = 'waiting'
            showBlip(girl.blip, true)
            say(girl, job.text.pickup)
        end
    end
end

-- ---------------------------------------------------------------- the job itself

local function cleanup()
    for _, girl in ipairs(girls) do
        dropBlip(girl.blip)
        dropBlip(girl.cblip)
        release(girl.ped)
        release(girl.customer)
        for _, rival in ipairs(girl.rivals or {}) do
            dropBlip(rival.blip)
            release(rival.ped)
        end
    end
    girls = {}
end

local function runGirl(girl, id, delay)
    CreateThread(function()
        Wait(delay)
        while session == id do
            -- pcall means: if something in step() breaks, print it and keep going
            local ok, err = pcall(step, girl)
            if not ok then
                print('[pimp] ' .. tostring(err))
            end
            Wait(250)
        end
    end)
end

FrameOS.registerJob('pimp', {
    -- you count as working while you drive, or while any girl is out with a customer
    isActive = function()
        if IsPedInAnyVehicle(PlayerPedId(), false) then
            return true
        end
        for _, girl in ipairs(girls) do
            if girl.state == 'working' or girl.state == 'problem' or girl.state == 'rival' then
                return true
            end
        end
        return false
    end,

    onStart = function()
        session = session + 1
        streak = 0
        girls = {}
        local count = FrameOS.jobRank('pimp').girls or 2
        for number = 1, count do
            local girl = { state = 'spawn', name = job.names[math.random(1, #job.names)] }
            table.insert(girls, girl)
            runGirl(girl, session, (number - 1) * 8000)   -- the girls show up one by one
        end
        FrameOS.notify('Stop next to a girl to pick her up. Watch the map.')
    end,

    onStop = function()
        session = session + 1   -- every girl's thread sees this and ends
        cleanup()
    end,
})
