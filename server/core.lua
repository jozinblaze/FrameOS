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
-- a file over about 2 MB is set aside and a fresh one starts.
local function flushLog()
    if #logBuffer == 0 then
        return
    end
    local old = LoadResourceFile(resource, 'logs/frameos.log') or ''
    if #old > 2000000 then
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
        bag = {},          -- item name -> how many
        owned = {},        -- the cars you own
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

    if raw and not data then
        -- the file exists but is unreadable. keep it safe and do NOT overwrite it.
        SaveResourceFile(resource, path .. '.broken-' .. os.time(), raw, -1)
        FrameOS.log('error', source, 'player file could not be read, saved a copy as .broken and started fresh')
        data = nil
    end

    local fresh = (data == nil)
    data = data or defaults()
    for key, value in pairs(defaults()) do
        if data[key] == nil then
            data[key] = value
        end
    end

    records[source] = { id = id, path = path, data = data, dirty = fresh }
    return records[source]
end

local function saveRecord(record)
    SaveResourceFile(resource, record.path, json.encode(record.data, { indent = true }), -1)
    record.dirty = false
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
    TriggerClientEvent('frameos:joined', source)
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
