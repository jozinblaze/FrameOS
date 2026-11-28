-- character: the saved character (name, sex, face and hair, outfit) lives on the server in d.character.
-- the screen sends a whole character when the creator is finished, and the server checks every
-- field against the lists in data/character.lua and keeps only a cleaned copy. whatever the screen
-- sent that does not fit is thrown away or clamped, so a modified client cannot save anything the
-- creator could not have made.
--
--   FrameOS.cleanCharacter(payload)   returns a clean character table, or nil and a reason
--
-- rules for saving: a player with no character can save one once. a player who has one cannot
-- change it, except an admin while Config.testCommands is on (that is what /creator uses).
-- barbers and clothing stores will get their own requests later.

local C = Config.character

local function no(why)
    return { ok = false, why = why }
end

local function number(value, low, high, default)
    value = tonumber(value)
    if not value or value ~= value then       -- not a number (value ~= value catches NaN)
        return default
    end
    return math.max(low, math.min(high, value))
end

local function whole(value, low, high, default)
    local n = number(value, low, high, nil)
    if n == nil then
        return default
    end
    return math.floor(n + 0.5)
end

-- is this a number from a parent list ({ { number, name }, ... })? otherwise the first one in the list
local function parent(value, list)
    value = tonumber(value)
    for _, entry in ipairs(list) do
        if entry[1] == value then
            return value
        end
    end
    return list[1][1]
end

local function round(n)
    return math.floor(n * 100 + 0.5) / 100
end

-- "jason" -> "Jason", only letters, spaces, apostrophes and hyphens
local function cleanName(text)
    if type(text) ~= 'string' then
        return nil
    end
    text = text:gsub('^%s+', ''):gsub('%s+$', ''):gsub('%s+', ' ')
    if #text < C.nameMin or #text > C.nameMax or not text:match("^[%a][%a '%-]*$") then
        return nil
    end
    return (text:gsub("(%a)([%w']*)", function(first, rest)
        return first:upper() .. rest:lower()
    end))
end

-- the outfit: only the slots in the lists, numbers kept to a sane size. always returns a clean table.
FrameOS.cleanName = cleanName   -- other server files use the same name rules

function FrameOS.cleanOutfit(sent)
    local outfit = type(sent) == 'table' and sent or {}
    local clean = { parts = {}, props = {} }
    local allowedPart, allowedProp = {}, {}
    for _, id in ipairs(C.outfitParts) do allowedPart[id] = true end
    for _, id in ipairs(C.outfitProps) do allowedProp[id] = true end
    for _, part in ipairs(type(outfit.parts) == 'table' and outfit.parts or {}) do
        if type(part) == 'table' and allowedPart[tonumber(part.id)] then
            table.insert(clean.parts, {
                id = math.floor(tonumber(part.id)),
                drawable = whole(part.drawable, 0, 500, 0),
                texture = whole(part.texture, 0, 100, 0),
            })
        end
    end
    for _, prop in ipairs(type(outfit.props) == 'table' and outfit.props or {}) do
        if type(prop) == 'table' and allowedProp[tonumber(prop.id)] then
            table.insert(clean.props, {
                id = math.floor(tonumber(prop.id)),
                drawable = whole(prop.drawable, -1, 500, -1),
                texture = whole(prop.texture, 0, 100, 0),
            })
        end
    end
    return clean
end

-- the look (face, skin, hair, eyes): every number kept inside its list. always returns a clean table.
function FrameOS.cleanLook(look)
    look = type(look) == 'table' and look or {}
    local hair = type(look.hair) == 'table' and look.hair or {}
    local clean = {
        mother = parent(look.mother, C.mothers),
        father = parent(look.father, C.fathers),
        shapeMix = round(number(look.shapeMix, 0, 1, 0.5)),
        skinMix = round(number(look.skinMix, 0, 1, 0.5)),
        features = {},
        overlays = {},
        hair = {
            style = whole(hair.style, 0, C.hairMax, 0),
            color = whole(hair.color, 0, C.hairColors, 0),
            highlight = whole(hair.highlight, 0, C.hairColors, 0),
        },
        eyes = whole(look.eyes, 0, C.eyeColors, 0),
    }

    local features = type(look.features) == 'table' and look.features or {}
    for i = 1, #C.features do
        clean.features[i] = round(number(features[i], -1, 1, 0))
    end

    -- overlays are a list of { id, style, opacity, color }. an overlay that is off is simply not in the list.
    -- (a list, not a table keyed by id, because the saved file turns number keys into text)
    local byId = {}
    for _, def in ipairs(C.overlays) do
        byId[def.id] = def
    end
    local seen = {}
    for _, sent in ipairs(type(look.overlays) == 'table' and look.overlays or {}) do
        local def = type(sent) == 'table' and byId[tonumber(sent.id)]
        local style = def and tonumber(sent.style)
        if def and not seen[def.id] and style and style >= 0 and style <= def.max then
            seen[def.id] = true
            table.insert(clean.overlays, {
                id = def.id,
                style = math.floor(style),
                opacity = round(number(sent.opacity, 0, 1, 1)),
                color = def.color and whole(sent.color, 0, C.hairColors, 0) or 0,
            })
        end
    end
    return clean
end

function FrameOS.cleanCharacter(p)
    if type(p) ~= 'table' or type(p.name) ~= 'table' or type(p.look) ~= 'table' then
        return nil, 'Bad character'
    end
    local first, last = cleanName(p.name.first), cleanName(p.name.last)
    if not first or not last then
        return nil, 'Names need ' .. C.nameMin .. ' to ' .. C.nameMax .. ' letters'
    end
    if p.sex ~= 'm' and p.sex ~= 'f' then
        return nil, 'Bad character'
    end
    return {
        name = { first = first, last = last },
        sex = p.sex,
        look = FrameOS.cleanLook(p.look),
        outfit = FrameOS.cleanOutfit(p.outfit),
    }
end

FrameOS.onAsk('saveCharacter', function(source, payload)
    local d = FrameOS.getPlayer(source)
    if d.character and not (Config.testCommands and FrameOS.isAdmin(source)) then
        FrameOS.log('refused', source, 'tried to change an existing character')
        return no('You already have a character')
    end
    local clean, why = FrameOS.cleanCharacter(payload)
    if not clean then
        return no(why)
    end
    d.character = clean
    FrameOS.markDirty(source)
    FrameOS.log('character', source, 'saved ' .. clean.name.first .. ' ' .. clean.name.last .. ' (' .. clean.sex .. ')')
    FrameOS.push(source)
    return { ok = true }
end, { every = 2000 })

-- who is this player, for other server files: "Jason Blazze", or nil if they have no character yet
function FrameOS.characterName(source)
    local d = FrameOS.getPlayer(source)
    if d and d.character then
        return d.character.name.first .. ' ' .. d.character.name.last
    end
    return nil
end

-- /saveclothes: saves what you are wearing right now as your character's outfit. admins only, and only
-- while Config.testCommands is on. it is how the starter outfits in data/character.lua get tuned,
-- until the clothing stores do this properly.
FrameOS.onAsk('saveClothes', function(source, outfit)
    local d = FrameOS.getPlayer(source)
    if not (Config.testCommands and FrameOS.isAdmin(source)) then
        return no('Admins only')
    end
    if not d.character then
        return no('You have no character yet')
    end
    d.character.outfit = FrameOS.cleanOutfit(outfit)
    FrameOS.markDirty(source)
    FrameOS.log('character', source, 'saved the outfit they are wearing')
    FrameOS.push(source)
    return { ok = true }
end, { every = 1000 })
