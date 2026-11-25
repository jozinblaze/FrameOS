-- jobs: the engine every job uses. clock in at a job's spot (press E),
-- work, get paid while you are actually working, rank up.
--
-- what this file does:  clock in and out, one job at a time, the payout timer,
--                       reputation and rank, the "on duty" line, stop on death.
-- what it does NOT do:  decide what working means. each job has a file in
--                       modules/jobs/ that registers itself with FrameOS.registerJob.
--
-- other modules can use:
--   FrameOS.registerJob(id, { isActive = fn, onStart = fn, onStop = fn })
--   FrameOS.currentJob()       the id you are working, or nil
--   FrameOS.jobPay(id, amount, rep)   the ONE place job money is given out.
--                              when saving moves to the server, this is the
--                              function that changes (the server will decide the pay).
-- commands: /clockout and /jobstats. /job <name> is a test command.

local handlers = {}                 -- job id -> the job's own behavior
local rep = FrameOS.load('jobrep', {})   -- job id -> reputation points
local current = nil                 -- the job you are on duty for (resets on relog)
local activeMs = 0                  -- active time since the last payout
local idleMs = 0                    -- time since the job was last active

function FrameOS.registerJob(id, handler)
    handlers[id] = handler
end

function FrameOS.currentJob()
    return current
end

-- the rank for a number of reputation points
local function rankFor(id, points)
    local list = (Jobs[id] and Jobs[id].ranks) or JobRanks
    local best = list[1]
    for _, rank in ipairs(list) do
        if points >= rank.rep then
            best = rank
        end
    end
    return best
end

-- gives pay and reputation. every job payout goes through here.
function FrameOS.jobPay(id, amount, points)
    local before = rankFor(id, rep[id] or 0)
    rep[id] = (rep[id] or 0) + (points or 0)
    FrameOS.save('jobrep', rep)
    FrameOS.addCash(amount)
    local after = rankFor(id, rep[id])
    if after.name ~= before.name then
        FrameOS.notify('New rank: ' .. after.name .. ' ' .. Jobs[id].label)
    end
end

local function clockOut(reason)
    if not current then
        return
    end
    local id = current
    current = nil
    if handlers[id] and handlers[id].onStop then
        handlers[id].onStop()
    end
    FrameOS.notify(reason or ('Clocked out: ' .. Jobs[id].label))
end

local function clockIn(id)
    if not Jobs[id] then
        FrameOS.notify('No job called ' .. id)
        return
    end
    if not handlers[id] then
        FrameOS.notify(Jobs[id].label .. ' is not ready yet')
        return
    end
    if current then
        clockOut()
    end
    current = id
    activeMs = 0
    idleMs = 0
    if handlers[id].onStart then
        handlers[id].onStart()
    end
    FrameOS.notify('Clocked in: ' .. Jobs[id].label)
end

-- map icons for the job spots
for id, job in pairs(Jobs) do
    if job.spot then
        local look = job.blip or { sprite = 280, color = 5 }
        FrameOS.addBlip(job.spot.x, job.spot.y, job.spot.z, look.sprite, look.color, job.label)
    end
end

-- the clock: every second, see if you are working and count it
CreateThread(function()
    while true do
        Wait(1000)
        if current then
            local job = Jobs[current]
            local handler = handlers[current]

            if IsEntityDead(PlayerPedId()) then
                clockOut('You died. Clocked out.')
            elseif handler.isActive() then
                idleMs = 0
                activeMs = activeMs + 1000
                if activeMs >= job.every then
                    activeMs = 0
                    local amount = math.random(job.pay.min, job.pay.max)
                    amount = math.floor(amount * rankFor(current, rep[current] or 0).bonus)
                    FrameOS.jobPay(current, amount, job.repPerPay)
                end
            else
                idleMs = idleMs + 1000
                if idleMs >= (job.idle or Config.jobIdleLimit) then
                    clockOut('Clocked out for being idle: ' .. job.label)
                end
            end
        end
    end
end)

-- the spots: a marker, press E on foot to clock in, or out if it is your job
CreateThread(function()
    while true do
        local sleep = 500
        local ped = PlayerPedId()
        local coords = GetEntityCoords(ped)
        for id, job in pairs(Jobs) do
            if job.spot then
                local dist = #(coords - vector3(job.spot.x, job.spot.y, job.spot.z))
                if dist < 30.0 then
                    sleep = 0
                    DrawMarker(1, job.spot.x, job.spot.y, job.spot.z - 1.0,
                        0.0, 0.0, 0.0, 0.0, 0.0, 0.0,
                        1.5, 1.5, 0.6,
                        255, 200, 60, 150,
                        false, false, 2, false, nil, nil, false)
                    if dist < 1.5 and not IsPedInAnyVehicle(ped, false) then
                        if current == id then
                            FrameOS.help('Press ~INPUT_CONTEXT~ to clock out of ' .. job.label)
                        else
                            FrameOS.help('Press ~INPUT_CONTEXT~ to work as ' .. job.label)
                        end
                        if IsControlJustPressed(0, 38) then   -- 38 is the E key
                            if current == id then
                                clockOut()
                            else
                                clockIn(id)
                            end
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- a small line under the cash counter while you are on duty
CreateThread(function()
    while true do
        if current then
            local rank = rankFor(current, rep[current] or 0)
            SetTextFont(4)
            SetTextScale(0.4, 0.4)
            SetTextColour(255, 220, 80, 230)
            SetTextOutline()
            SetTextRightJustify(true)
            SetTextWrap(0.0, 0.985)
            BeginTextCommandDisplayText('STRING')
            AddTextComponentSubstringPlayerName(Jobs[current].label .. ' - ' .. rank.name)
            EndTextCommandDisplayText(0.0, 0.08)
            Wait(0)
        else
            Wait(500)
        end
    end
end)

FrameOS.command('clockout', 'stops working your current job', function()
    if current then
        clockOut()
    else
        FrameOS.notify('You are not working')
    end
end)

FrameOS.command('jobstats', 'shows your rank and reputation for every job', function()
    for id, job in pairs(Jobs) do
        local points = rep[id] or 0
        FrameOS.notify(job.label .. ': ' .. rankFor(id, points).name .. ' (' .. points .. ' rep)')
    end
end)

FrameOS.testCommand('job', 'clock in without walking to the spot, example: /job courier', function(source, args)
    if args[1] then
        clockIn(string.lower(args[1]))
    else
        local names = {}
        for id, _ in pairs(Jobs) do
            table.insert(names, id)
        end
        table.sort(names)
        FrameOS.notify('Jobs: ' .. table.concat(names, ', '))
    end
end)
