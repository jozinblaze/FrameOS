-- server core: the part of FrameOS that runs on the server.
-- the server is the one that knows the truth about money, items and cars.
-- a player's screen can ask for things, and the server checks and decides.
--
-- what is in here:
--   saved player data   one readable file per player in the playerdata/ folder
--   asking              FrameOS.onAsk(name, fn): the client calls FrameOS.ask(name, ...)
--   rate limits         a player can't flood the server with requests
--   the log             every important thing is written to logs/frameos.log
--   admin check         FrameOS.isAdmin(source)
-- later server files (money, shops, jobs) are built on top of these.

FrameOS = {}

local resource = GetCurrentResourceName()
local records = {}        -- player source -> { id, path, data, dirty }
local askHandlers = {}    -- request name -> { fn, every }
local floods = {}         -- player source -> { count, since }
local lastAsk = {}        -- "source:name" -> time of the last request
local logBuffer = {}      -- log lines waiting to be written to the file

-- ---------------------------------------------------------------- the log

function FrameOS.log(kind, source, text)
    local who = 'server'
    if source and source > 0 then
        who = (GetPlayerName(source) or '?') .. ' (' .. ((records[source] and records[source].id) or '?') .. ')'
    end
    local line = os.date('%Y-%m-%d %H:%M:%S') .. ' [' .. kind .. '] ' .. who .. ' ' .. text
    print('[FrameOS] ' .. line)
    table.insert(logBuffer, line)
end

-- writes the waiting lines to the file every 10 seconds.
-- a file over about 400 KB is set aside and a fresh one starts (the whole file is
-- read again on every write, so a small file keeps this cheap).
local function flushLog()
    if #logBuffer == 0 then
        return
    end
    local old = LoadResourceFile(resource, 'logs/frameos.log') or ''
    if #old > 400000 then
        SaveResourceFile(resource, 'logs/frameos-' .. os.date('%Y%m%d-%H%M%S') .. '.log', old, -1)
        old = ''
    end
    SaveResourceFile(resource, 'logs/frameos.log', old .. table.concat(logBuffer, '\n') .. '\n', -1)
    logBuffer = {}
end

CreateThread(function()
    while true do
        Wait(10000)
        flushLog()
    end
end)

-- ---------------------------------------------------------------- who is who

-- the player's license identifier, the same one every time they join
local function licenseOf(source)
    local id = GetPlayerIdentifierByType(source, 'license')
    if id then
        return id
    end
    for _, identifier in ipairs(GetPlayerIdentifiers(source)) do
        if identifier:sub(1, 8) == 'license:' then
            return identifier
        end
    end
    return nil
end

-- admins are the identifiers in Config.admins, or anyone with the frameos.admin
-- permission in server.cfg. source 0 is the server console.
function FrameOS.isAdmin(source)
    if source == 0 then
        return true
    end
    local id = (records[source] and records[source].id) or licenseOf(source)
    for _, admin in ipairs(Config.admins or {}) do
        if admin == id then
            return true
        end
    end
    return IsPlayerAceAllowed(source, 'frameos.admin')
end

-- ---------------------------------------------------------------- saved player data

-- what a brand new player starts with. every key a player file is missing
-- is filled in from here, so adding a new key later never breaks old files.
local function defaults()
    return {
        version = 1,
        created = os.time(),
        cash = Config.startCash or 0,
        bank = 0,
        atmDay = '',       -- the day (YYYYMMDD) atmOut counts for
        atmOut = 0,        -- cash taken from ATMs today
        bag = {},          -- item name -> how many
        needs = { hunger = 100, thirst = 100 },   -- 0 to 100, see server/needs.lua
        owned = {},        -- the cars you own
        storage = {},      -- container id -> items (car trunks and gloveboxes by plate, safehouse stashes)
        nextCarId = 1,
        jobrep = {},       -- job id -> reputation
        imported = false,  -- true once the old saves from your own computer were copied up
    }
end

local function loadRecord(source)
    local id = licenseOf(source)
    if not id then
        return nil
    end
    local path = 'playerdata/' .. id:gsub('[^%w]', '_') .. '.json'
    local raw = LoadResourceFile(resource, path)
    local data = raw and json.decode(raw)
    if raw and type(data) ~= 'table' then
        data = nil
    end

    if raw and not data then
        -- the file exists but is unreadable. keep it safe and do NOT overwrite it.
        SaveResourceFile(resource, path .. '.broken-' .. os.time(), raw, -1)
        FrameOS.log('error', source, 'player file could not be read, saved a copy as .broken and started fresh')
        data = nil
    end

    -- a copy of the file as it was when the player loaded in, one per day, so a bad
    -- update or a mistake can always be rolled back (playerdata/backups/)
    if raw and data then
        SaveResourceFile(resource, 'playerdata/backups/' .. id:gsub('[^%w]', '_') .. '-' .. os.date('%Y%m%d') .. '.json', raw, -1)
    end

    local fresh = (data == nil)
    data = data or defaults()
    for key, value in pairs(defaults()) do
        if data[key] == nil then
            data[key] = value
        end
    end

    -- keys inside tables that older files only half have
    if type(data.needs) ~= 'table' then
        data.needs = { hunger = 100, thirst = 100 }
    end
    data.needs.hunger = tonumber(data.needs.hunger) or 100
    data.needs.thirst = tonumber(data.needs.thirst) or 100

    records[source] = { id = id, path = path, data = data, dirty = fresh }
    return records[source]
end

-- writes a player's file. if the write fails the record stays dirty, so the next
-- 30 second save tries again, and the failure is logged instead of being silent.
local function saveRecord(record)
    local ok = SaveResourceFile(resource, record.path, json.encode(record.data, { indent = true }), -1)
    if ok == false then
        print('[FrameOS] ERROR: could not save ' .. record.path .. ', will try again')
        record.failed = (record.failed or 0) + 1
        record.dirty = true
        return false
    end
    record.failed = nil
    record.dirty = false
    return true
end

-- calls fn(source, data) for every player who is loaded in
function FrameOS.eachPlayer(fn)
    for source, record in pairs(records) do
        fn(source, record.data)
    end
end

-- modules register things to do when a player wakes up at the hospital:
-- FrameOS.onRespawn(function(source, data) ... end). economy.lua runs them.
FrameOS.respawnHooks = {}
function FrameOS.onRespawn(fn)
    table.insert(FrameOS.respawnHooks, fn)
end

-- the player's license id, or nil if they have not loaded in yet
function FrameOS.idOf(source)
    return records[source] and records[source].id
end

-- the player's data table, or nil if they have not loaded in yet
function FrameOS.getPlayer(source)
    return records[source] and records[source].data
end

-- call this after changing a player's data, so it gets saved
function FrameOS.markDirty(source)
    if records[source] then
        records[source].dirty = true
    end
end

-- saves everyone who changed, every 30 seconds
CreateThread(function()
    while true do
        Wait(30000)
        for _, record in pairs(records) do
            if record.dirty then
                saveRecord(record)
            end
        end
    end
end)

AddEventHandler('playerDropped', function()
    local source = source
    local record = records[source]
    if record then
        saveRecord(record)
        FrameOS.log('leave', source, 'saved and left')
        records[source] = nil
    end
    floods[source] = nil
    for key in pairs(lastAsk) do
        if key:match('^' .. source .. ':') then
            lastAsk[key] = nil
        end
    end
end)

AddEventHandler('onResourceStop', function(name)
    if name ~= resource then
        return
    end
    for _, record in pairs(records) do
        saveRecord(record)
    end
    flushLog()
end)

-- the client says hello when it starts, which loads (or creates) its data
RegisterNetEvent('frameos:join', function()
    local source = source
    if not records[source] then
        if not loadRecord(source) then
            FrameOS.log('error', source, 'no license identifier, cannot load data')
            return
        end
        FrameOS.log('join', source, 'data loaded')
    end
    -- tell the client whether its old saves were copied up yet, then send its data
    TriggerClientEvent('frameos:joined', source, records[source].data.imported)
    if FrameOS.push then
        FrameOS.push(source)
    end
end)

-- ---------------------------------------------------------------- asking

-- registers something the client can ask for.
--   fn(source, ...) does the work and returns the answer (one value, a table is fine)
--   options.every   least milliseconds between two of these from the same player
--   options.noData  true = also works before the player's data is loaded
function FrameOS.onAsk(name, fn, options)
    options = options or {}
    askHandlers[name] = { fn = fn, every = options.every, noData = options.noData }
end

local function answer(source, id, ok, result)
    TriggerClientEvent('frameos:answer', source, id, ok, result)
end

RegisterNetEvent('frameos:ask', function(id, name, ...)
    local source = source
    if type(id) ~= 'number' or type(name) ~= 'string' then
        return
    end

    -- more than 40 requests in one second is not a person playing
    local now = GetGameTimer()
    local flood = floods[source]
    if not flood or now - flood.since > 1000 then
        flood = { count = 0, since = now }
        floods[source] = flood
    end
    flood.count = flood.count + 1
    if flood.count > 40 then
        if flood.count == 41 then
            FrameOS.log('flood', source, 'too many requests (' .. name .. ')')
        end
        return
    end

    local handler = askHandlers[name]
    if not handler then
        answer(source, id, false, 'unknown request')
        return
    end

    local key = source .. ':' .. name
    if handler.every and lastAsk[key] and now - lastAsk[key] < handler.every then
        answer(source, id, false, 'too fast')
        return
    end
    lastAsk[key] = now

    if not records[source] and not handler.noData then
        answer(source, id, false, 'not loaded')
        return
    end

    -- if the handler breaks, log it and tell the player something went wrong
    local ok, result = pcall(handler.fn, source, ...)
    if ok then
        answer(source, id, true, result)
    else
        FrameOS.log('error', source, name .. ' failed: ' .. tostring(result))
        answer(source, id, false, 'server error')
    end
end)

-- ---------------------------------------------------------------- first requests

-- your license identifier, to paste into Config.admins in config.lua
FrameOS.onAsk('myid', function(source)
    return licenseOf(source)
end, { noData = true })

-- what the server knows about you, for /serverstatus
FrameOS.onAsk('status', function(source)
    local data = FrameOS.getPlayer(source)
    return {
        id = records[source].id,
        admin = FrameOS.isAdmin(source),
        cash = data.cash,
        bank = data.bank,
        cars = #data.owned,
    }
end)
