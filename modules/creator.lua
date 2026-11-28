-- creator: the character creator menu. it opens by itself the first time you join (no character
-- yet, see modules/character.lua), and /creator reopens it (admin test command).
-- a camera looks at your ped, the menu is on the left. same controls as the bank and shops:
--   Up / Down choose      Left / Right change (hold to go faster)      Enter open or press
--   Backspace go back     A / D turn your character     E switch between face and full body camera
-- every change shows on your ped right away. nothing is saved until you press Finish, then the
-- server checks the whole thing (server/character.lua) and keeps it.
-- everything you can pick is listed in data/character.lua.

local C = Config.character

local function clamp(n, low, high)
    return math.max(low, math.min(high, n))
end

-- ---------------------------------------------------------------- small helpers

-- left / right / up / down with key repeat: true on the press, then again every 70 ms after holding 400 ms
local holds = {}
local function pressed(control)
    local now = GetGameTimer()
    if IsControlJustPressed(0, control) then
        holds[control] = now + 400
        return true
    end
    if IsControlPressed(0, control) and holds[control] and now > holds[control] then
        holds[control] = now + 70
        return true
    end
    return false
end

-- the game's own keyboard box. returns the text, or nil if you cancel.
local function askText(label, default, max)
    AddTextEntry('FRAMEOS_TXT', label)
    DisplayOnscreenKeyboard(1, 'FRAMEOS_TXT', '', default or '', '', '', '', max)
    while UpdateOnscreenKeyboard() == 0 do
        Wait(0)
        DisableAllControlActions(0)
    end
    local result = nil
    if UpdateOnscreenKeyboard() == 1 then
        result = GetOnscreenKeyboardResult()
    end
    Wait(250)   -- so the Enter that closed the box is not also used in the menu
    return result
end

-- ---------------------------------------------------------------- what the menu edits

local function newState()
    local features = {}
    for i = 1, #C.features do
        features[i] = 0.0
    end
    return {
        sex = 'm',
        name = { first = '', last = '' },
        outfit = 1,
        look = {
            mother = C.mothers[1][1], father = C.fathers[1][1], shapeMix = 0.5, skinMix = 0.5,
            features = features,
            overlays = {},        -- while editing: overlay id -> { style, opacity, color }
            hair = { style = 0, color = 0, highlight = 0 },
            eyes = 0,
        },
    }
end

-- a saved character -> what the menu edits (overlays go from a list to a table keyed by id)
local function stateFrom(saved)
    local state = newState()
    state.sex = saved.sex
    state.name = { first = saved.name.first, last = saved.name.last }
    local look = saved.look
    state.look.mother, state.look.father = look.mother, look.father
    state.look.shapeMix, state.look.skinMix = look.shapeMix, look.skinMix
    for i = 1, #C.features do
        state.look.features[i] = look.features[i] or 0.0
    end
    for _, overlay in ipairs(look.overlays or {}) do
        state.look.overlays[overlay.id] = { style = overlay.style, opacity = overlay.opacity, color = overlay.color }
    end
    state.look.hair = { style = look.hair.style, color = look.hair.color, highlight = look.hair.highlight }
    state.look.eyes = look.eyes
    state.outfitData = saved.outfit
    return state
end

-- what is sent to the server (overlays back to a list)
local function payloadFrom(state)
    local overlays = {}
    for _, def in ipairs(C.overlays) do
        local overlay = state.look.overlays[def.id]
        if overlay then
            table.insert(overlays, { id = def.id, style = overlay.style, opacity = overlay.opacity, color = overlay.color })
        end
    end
    return {
        name = state.name,
        sex = state.sex,
        look = {
            mother = state.look.mother, father = state.look.father,
            shapeMix = state.look.shapeMix, skinMix = state.look.skinMix,
            features = state.look.features, overlays = overlays,
            hair = state.look.hair, eyes = state.look.eyes,
        },
        outfit = state.outfitData,
    }
end

-- ---------------------------------------------------------------- menu rows
-- a row is { label, text = function() -> what to show on the right, left = fn, right = fn, enter = fn }

local function choiceRow(label, get, set, low, high, show)
    local function step(direction)
        local value = get() + direction
        if value < low then value = high elseif value > high then value = low end
        set(value)
    end
    return {
        label = label,
        text = function() return show and show(get()) or tostring(get()) end,
        left = function() step(-1) end,
        right = function() step(1) end,
    }
end

local function sliderRow(label, get, set, low, high, step, show)
    local function move(direction)
        set(clamp(math.floor((get() + direction * step) * 100 + 0.5) / 100, low, high))
    end
    return {
        label = label,
        text = function() return show and show(get()) or string.format('%.2f', get()) end,
        left = function() move(-1) end,
        right = function() move(1) end,
    }
end

-- where a parent's game number sits in its list, and the name the menu shows for it
local function parentIndex(list, number)
    for i, entry in ipairs(list) do
        if entry[1] == number then
            return i
        end
    end
    return 1
end

local function percent(value)
    return string.format('%d%%', math.floor(value * 100 + 0.5))
end

local function signed(value)
    return string.format('%+d', math.floor(value * 100 + 0.5))
end

-- ---------------------------------------------------------------- the creator

-- editing = true when you already have a character and are changing it (admin /creator): you can cancel.
-- returns true when a character was saved.
function FrameOS.openCreator(editing)
    local ped = PlayerPedId()
    local saved = FrameOS.data.character
    local state = (editing and saved) and stateFrom(saved) or newState()

    -- take over the screen
    FrameOS.uiHidden = true
    if IsScreenFadedOut() or IsScreenFadingOut() then
        DoScreenFadeIn(500)
    end
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)

    -- the camera: two views, worked out once from where you stand now. you can turn with A and D.
    local faceAt = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.62)
    local faceCam = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.85, 0.65)
    local bodyAt = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.05)
    local bodyCam = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.8, 0.45)
    local camera = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local view = 'body'

    local function setView(which)
        view = which
        local from, at, fov = bodyCam, bodyAt, 45.0
        if which == 'face' then
            from, at, fov = faceCam, faceAt, 32.0
        end
        SetCamCoord(camera, from.x, from.y, from.z)
        PointCamAtCoord(camera, at.x, at.y, at.z)
        SetCamFov(camera, fov)
    end
    setView('body')
    SetCamActive(camera, true)
    RenderScriptCams(true, true, 700, true, true)

    -- put the state on the ped. the model changes when the sex does.
    local function presetOutfit()
        local current = PlayerPedId()
        SetPedDefaultComponentVariation(current)
        local preset = C.outfits[state.outfit]
        local parts = {}
        for _, p in ipairs(preset.parts or {}) do
            table.insert(parts, { id = p[1], drawable = p[2], texture = p[3] })
        end
        FrameOS.applyOutfit(current, { parts = parts, props = {} })
        FrameOS.applyLook(current, state.look)
        state.outfitData = FrameOS.readOutfitParts(current)
    end

    local function refresh(modelChanged, outfitChanged)
        if modelChanged then
            local want = joaat(C.models[state.sex])
            if GetEntityModel(PlayerPedId()) ~= want then
                FrameOS.setModel(want)
            end
            local current = PlayerPedId()
            FreezeEntityPosition(current, true)
            SetEntityInvincible(current, true)
            presetOutfit()
        elseif outfitChanged then
            presetOutfit()
        else
            FrameOS.applyLook(PlayerPedId(), state.look)
        end
    end

    -- the first picture: for a new character the ped becomes the freemode ped of the default sex
    if editing and saved then
        FrameOS.applyCharacter(saved)
        FreezeEntityPosition(PlayerPedId(), true)
        SetEntityInvincible(PlayerPedId(), true)
    else
        refresh(true, true)
    end

    -- overlays: a "style" row, then opacity and color rows only while it is on
    local function overlayRows(rows, def)
        local overlays = state.look.overlays
        table.insert(rows, choiceRow(def.name, function()
            return overlays[def.id] and overlays[def.id].style or -1
        end, function(value)
            if value < 0 then
                overlays[def.id] = nil
            else
                overlays[def.id] = overlays[def.id] or { style = value, opacity = 1.0, color = 0 }
                overlays[def.id].style = value
            end
            refresh()
        end, -1, def.max, function(value) return value < 0 and 'None' or tostring(value) end))
        if overlays[def.id] then
            table.insert(rows, sliderRow('   Strength', function() return overlays[def.id].opacity end,
                function(value) overlays[def.id].opacity = value; refresh() end, 0.0, 1.0, 0.1, percent))
            if def.color then
                table.insert(rows, choiceRow('   Color', function() return overlays[def.id].color end,
                    function(value) overlays[def.id].color = value; refresh() end, 0, C.hairColors))
            end
        end
    end

    local function defById(id)
        for _, def in ipairs(C.overlays) do
            if def.id == id then return def end
        end
    end

    local function fullName()
        if state.name.first == '' and state.name.last == '' then
            return 'Not set'
        end
        return state.name.first .. ' ' .. state.name.last
    end

    -- the pages. each one builds its rows every frame, so rows can come and go (an overlay's strength).
    local pages = {}
    local stack = { 'main' }

    pages.parents = { title = 'Parents', build = function()
        return {
            choiceRow('Mother', function() return parentIndex(C.mothers, state.look.mother) end,
                function(v) state.look.mother = C.mothers[v][1]; refresh() end, 1, #C.mothers,
                function(v) return C.mothers[v][2] .. '  (' .. C.mothers[v][1] .. ')' end),
            choiceRow('Father', function() return parentIndex(C.fathers, state.look.father) end,
                function(v) state.look.father = C.fathers[v][1]; refresh() end, 1, #C.fathers,
                function(v) return C.fathers[v][2] .. '  (' .. C.fathers[v][1] .. ')' end),
            sliderRow('Face takes after', function() return state.look.shapeMix end,
                function(v) state.look.shapeMix = v; refresh() end, 0.0, 1.0, 0.05, function(v) return percent(v) .. ' father' end),
            sliderRow('Skin takes after', function() return state.look.skinMix end,
                function(v) state.look.skinMix = v; refresh() end, 0.0, 1.0, 0.05, function(v) return percent(v) .. ' father' end),
        }
    end }

    pages.face = { title = 'Face', build = function()
        local rows = {}
        for i = 1, #C.features do
            table.insert(rows, sliderRow(C.features[i], function() return state.look.features[i] end,
                function(v) state.look.features[i] = v; refresh() end, -1.0, 1.0, 0.1, signed))
        end
        return rows
    end }

    pages.skin = { title = 'Skin', build = function()
        local rows = {}
        for _, id in ipairs({ 0, 3, 6, 7, 9 }) do
            overlayRows(rows, defById(id))
        end
        return rows
    end }

    pages.hair = { title = 'Hair and eyes', build = function()
        local rows = {
            choiceRow('Hair style', function() return state.look.hair.style end,
                function(v) state.look.hair.style = v; refresh() end, 0,
                math.max(0, GetNumberOfPedDrawableVariations(PlayerPedId(), 2) - 1)),
            choiceRow('Hair color', function() return state.look.hair.color end,
                function(v) state.look.hair.color = v; refresh() end, 0, C.hairColors),
            choiceRow('Highlights', function() return state.look.hair.highlight end,
                function(v) state.look.hair.highlight = v; refresh() end, 0, C.hairColors),
            choiceRow('Eye color', function() return state.look.eyes end,
                function(v) state.look.eyes = v; refresh() end, 0, C.eyeColors),
        }
        for _, id in ipairs({ 2, 1, 10 }) do
            overlayRows(rows, defById(id))
        end
        return rows
    end }

    pages.makeup = { title = 'Makeup', build = function()
        local rows = {}
        for _, id in ipairs({ 4, 5, 8 }) do
            overlayRows(rows, defById(id))
        end
        return rows
    end }

    local function subpage(label, key)
        return { label = label, text = function() return '>' end, enter = function() table.insert(stack, key) end }
    end

    local done = false       -- Finish worked
    local leave = false      -- cancelled (only when editing)

    pages.main = { title = editing and 'Change your character' or 'Create your character', build = function()
        return {
            { label = 'Name', text = fullName, enter = function()
                local first = askText('First name', state.name.first, C.nameMax)
                if first then state.name.first = first end
                local last = askText('Last name', state.name.last, C.nameMax)
                if last then state.name.last = last end
            end },
            choiceRow('Gender', function() return state.sex == 'm' and 1 or 2 end,
                function(v) state.sex = v == 1 and 'm' or 'f'; refresh(true, true) end, 1, 2,
                function(v) return v == 1 and 'Male' or 'Female' end),
            subpage('Parents', 'parents'),
            subpage('Face', 'face'),
            subpage('Skin', 'skin'),
            subpage('Hair and eyes', 'hair'),
            subpage('Makeup', 'makeup'),
            choiceRow('Starting outfit', function() return state.outfit end,
                function(v) state.outfit = v; refresh(false, true) end, 1, #C.outfits,
                function(v) return C.outfits[v].name end),
            { label = 'Finish', text = function() return '' end, enter = function()
                if #state.name.first < C.nameMin or #state.name.last < C.nameMin then
                    FrameOS.notify('Set your name first')
                    return
                end
                if FrameOS.request('saveCharacter', payloadFrom(state)) then
                    done = true
                end
            end },
        }
    end }

    -- ---- the loop
    local index = 1
    local lastPage = 'main'
    local remembered = {}   -- page -> the row you were on, so going back lands where you left
    local heading = GetEntityHeading(PlayerPedId())
    while not done and not leave do
        Wait(0)
        local page = pages[stack[#stack]]
        local rows = page.build()
        if stack[#stack] ~= lastPage then
            remembered[lastPage] = index
            lastPage = stack[#stack]
            index = remembered[lastPage] or 1
        end
        index = clamp(index, 1, #rows)

        -- draw: a window of 11 rows around the chosen one
        FrameOS.drawText(page.title, 0.06, 0.10, 0.7)
        local first = clamp(index - 5, 1, math.max(1, #rows - 10))
        for slot = 0, math.min(10, #rows - first) do
            local row = rows[first + slot]
            local selected = (first + slot == index)
            local y = 0.18 + slot * 0.042
            local color = selected and { 255, 220, 80 } or { 255, 255, 255 }
            FrameOS.drawText((selected and '> ' or '  ') .. row.label, 0.06, y, 0.45, false, color)
            FrameOS.drawText(row.text(), 0.27, y, 0.45, false, color)
        end
        if first > 1 then FrameOS.drawText('...', 0.06, 0.15, 0.4) end
        if first + 10 < #rows then FrameOS.drawText('...', 0.06, 0.18 + 11 * 0.042, 0.4) end
        FrameOS.drawText('Up / Down choose    Left / Right change    Enter select    Backspace back',
            0.06, 0.90, 0.35)
        FrameOS.drawText('A / D turn    E face or full body camera', 0.06, 0.93, 0.35)

        -- turn the ped
        if IsControlPressed(0, 34) then
            heading = heading + 90.0 * GetFrameTime()
            SetEntityHeading(PlayerPedId(), heading)
        elseif IsControlPressed(0, 35) then
            heading = heading - 90.0 * GetFrameTime()
            SetEntityHeading(PlayerPedId(), heading)
        end
        if IsControlJustPressed(0, 38) then
            setView(view == 'body' and 'face' or 'body')
        end

        -- move around the menu
        if pressed(172) then
            index = index - 1
            if index < 1 then index = #rows end
        elseif pressed(173) then
            index = index % #rows + 1
        elseif pressed(174) then
            if rows[index].left then rows[index].left() end
        elseif pressed(175) then
            if rows[index].right then rows[index].right() end
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then
            if rows[index].enter then rows[index].enter() end
        elseif IsControlJustPressed(0, 177) then
            if #stack > 1 then
                table.remove(stack)
            elseif editing then
                leave = true
            else
                FrameOS.notify('Finish your character to start playing')
            end
        end
    end

    -- put the screen back
    RenderScriptCams(false, true, 700, true, true)
    Wait(700)
    DestroyCam(camera, false)
    if leave and saved then
        FrameOS.applyCharacter(saved)   -- cancelled: back to the saved look
    end
    local after = PlayerPedId()
    FreezeEntityPosition(after, false)
    SetEntityInvincible(after, false)
    FrameOS.uiHidden = false
    if done then
        FrameOS.notify('Welcome, ' .. state.name.first .. ' ' .. state.name.last)
    end
    return done
end

FrameOS.testCommand('creator', 'opens the character creator again (admins)', function()
    CreateThread(function()
        local editing = FrameOS.data.character ~= nil
        if editing then
            -- the server only lets admins change a saved character, so say so before the menu opens
            local ok, info = FrameOS.ask('status')
            if not (ok and info.admin) then
                FrameOS.notify('Only admins can change a saved character. Run /myid and put the id in local.lua')
                return
            end
        end
        FrameOS.openCreator(editing)
    end)
end)
