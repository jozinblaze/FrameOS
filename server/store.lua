-- store: the one place the server reads and writes saved data files.
-- everything else (player data today, containers or properties later) asks the store
-- instead of touching files itself. that keeps the way data is saved in ONE file: to move
-- to a database later, this is the file that changes and nothing else.
--
-- a collection is a folder and an id is a file in it:  store.read('playerdata', 'license:abc')
-- reads  playerdata/license_abc.json.  the id is made file-safe here, callers never do that.
--
--   FrameOS.store.path(collection, id)            the file path
--   FrameOS.store.read(collection, id)            data, raw
--        data = the table, or nil.  raw = the file text, or nil if there is no file.
--        data nil with raw set means the file exists but is unreadable or not a table.
--   FrameOS.store.write(collection, id, data)     true, or false if the write failed
--   FrameOS.store.copy(collection, id, tag, raw)  keeps a copy of raw text in collection/backups/
--   FrameOS.store.setAside(collection, id, raw)   keeps an unreadable file as .broken-<time>

local resource = GetCurrentResourceName()

FrameOS.store = {}

local function safe(id)
    return (tostring(id):gsub('[^%w]', '_'))
end

function FrameOS.store.path(collection, id)
    return collection .. '/' .. safe(id) .. '.json'
end

function FrameOS.store.read(collection, id)
    local raw = LoadResourceFile(resource, FrameOS.store.path(collection, id))
    if not raw then
        return nil, nil
    end
    local data = json.decode(raw)
    if type(data) ~= 'table' then
        return nil, raw
    end
    return data, raw
end

function FrameOS.store.write(collection, id, data)
    local ok = SaveResourceFile(resource, FrameOS.store.path(collection, id), json.encode(data, { indent = true }), -1)
    return ok ~= false
end

function FrameOS.store.copy(collection, id, tag, raw)
    SaveResourceFile(resource, collection .. '/backups/' .. safe(id) .. '-' .. tostring(tag) .. '.json', raw, -1)
end

function FrameOS.store.setAside(collection, id, raw)
    SaveResourceFile(resource, FrameOS.store.path(collection, id) .. '.broken-' .. os.time(), raw, -1)
end
