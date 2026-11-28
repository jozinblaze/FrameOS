-- menu: the on-screen menu the creator, the clothing stores, the barbers and the wardrobes all use.
-- one place for the controls, so they feel the same everywhere:
--   Up / Down choose      Left / Right change (hold to go faster, hold Shift for steps of 10)
--   Enter open or press   Backspace go back     A / D turn your character     E face or full body camera
--
--   FrameOS.menu.choiceRow(label, get, set, low, high, show)   a number you step through, wraps around
--   FrameOS.menu.sliderRow(label, get, set, low, high, step, show)
--   FrameOS.menu.askText(label, default, max)                  the game's keyboard box, nil if cancelled
--   FrameOS.menu.camera()                                      starts the camera on your ped, returns it
--                                                              (camera.toggle() switches face / body, camera.close() puts it back)
--   FrameOS.menu.run(def)                                      runs the menu until def.finished() is true
-- a row is { label, text = function() -> the right side, left = fn, right = fn, enter = fn }.
-- def = { pages = { main = { title, build = function() -> rows } }, finished = fn, root = fn (Backspace on the first
-- page), camera = the camera from FrameOS.menu.camera() }. pages build their rows every frame, so rows can come and go.

FrameOS.menu = {}
local menu = FrameOS.menu

local function clamp(n, low, high)
    return math.max(low, math.min(high, n))
end

-- left / right / up / down with key repeat: true on the press, then again every 70 ms after holding 400 ms
local holds = {}
function menu.pressed(control)
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

function menu.askText(label, default, max)
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

-- holding Shift makes a step ten times bigger (only the number rows use it)
local function shiftHeld()
    return IsControlPressed(0, 21)
end

function menu.choiceRow(label, get, set, low, high, show)
    local function step(direction)
        local jump = shiftHeld() and 10 or 1
        local value = get() + direction * jump
        if value < low then
            value = (jump > 1 and get() > low) and low or high
        elseif value > high then
            value = (jump > 1 and get() < high) and high or low
        end
        set(value)
    end
    return {
        label = label,
        text = function() return show and show(get()) or tostring(get()) end,
        left = function() step(-1) end,
        right = function() step(1) end,
    }
end

function menu.sliderRow(label, get, set, low, high, step, show)
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

-- the camera: two views, worked out once from where you stand now
function menu.camera()
    local ped = PlayerPedId()
    local faceAt = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.62)
    local faceFrom = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.85, 0.65)
    local bodyAt = GetOffsetFromEntityInWorldCoords(ped, 0.0, 0.0, 0.05)
    local bodyFrom = GetOffsetFromEntityInWorldCoords(ped, 0.0, 2.8, 0.45)
    local cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    local camera = { view = 'body' }

    function camera.set(which)
        camera.view = which
        local from, at, fov = bodyFrom, bodyAt, 45.0
        if which == 'face' then
            from, at, fov = faceFrom, faceAt, 32.0
        end
        SetCamCoord(cam, from.x, from.y, from.z)
        PointCamAtCoord(cam, at.x, at.y, at.z)
        SetCamFov(cam, fov)
    end
    function camera.toggle()
        camera.set(camera.view == 'body' and 'face' or 'body')
    end
    function camera.close()
        RenderScriptCams(false, true, 700, true, true)
        Wait(700)
        DestroyCam(cam, false)
    end

    camera.set('body')
    SetCamActive(cam, true)
    RenderScriptCams(true, true, 700, true, true)
    return camera
end

function menu.run(def)
    local stack = { 'main' }
    local index = 1
    local lastPage = 'main'
    local remembered = {}   -- page -> the row you were on, so going back lands where you left
    local heading = GetEntityHeading(PlayerPedId())

    menu.openPage = function(key)   -- rows use this to open a sub page
        table.insert(stack, key)
    end
    menu.goBack = function()        -- ... and this to go back one page
        if #stack > 1 then table.remove(stack) end
    end

    while not def.finished() do
        Wait(0)
        local page = def.pages[stack[#stack]]
        local rows = page.build()
        if stack[#stack] ~= lastPage then
            remembered[lastPage] = index
            lastPage = stack[#stack]
            index = remembered[lastPage] or 1
        end
        index = clamp(index, 1, math.max(1, #rows))

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
        FrameOS.drawText('Up / Down choose    Left / Right change (Shift = 10)    Enter select    Backspace back',
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
        if def.camera and IsControlJustPressed(0, 38) then
            def.camera.toggle()
        end

        -- move around the menu
        if #rows == 0 then
            -- an empty page: only going back works
        elseif menu.pressed(172) then
            index = index - 1
            if index < 1 then index = #rows end
        elseif menu.pressed(173) then
            index = index % #rows + 1
        elseif menu.pressed(174) then
            if rows[index].left then rows[index].left() end
        elseif menu.pressed(175) then
            if rows[index].right then rows[index].right() end
        elseif IsControlJustPressed(0, 191) or IsControlJustPressed(0, 18) then
            if rows[index].enter then rows[index].enter() end
        end
        if IsControlJustPressed(0, 177) then
            if #stack > 1 then
                table.remove(stack)
            elseif def.root then
                def.root()
            end
        end
    end
end
