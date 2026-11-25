-- core: the shared parts every module uses.
-- everything lives inside one table called FrameOS.

FrameOS = {}
FrameOS.commandList = {}   -- every command, so /frameos can list them
FrameOS.spawnTasks = {}    -- things to do each time you spawn in

-- shows a message in the corner of the screen and in the F8 console
function FrameOS.notify(text)
    print('[FrameOS] ' .. text)
    BeginTextCommandThefeedPost('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandThefeedPostTicker(false, false)
end

-- saves any table or value under a name (survives restarts)
function FrameOS.save(key, value)
    SetResourceKvp('frameos_' .. key, json.encode(value))
end

-- reads it back. if nothing was saved yet, you get the default
function FrameOS.load(key, default)
    local saved = GetResourceKvpString('frameos_' .. key)
    if saved then
        return json.decode(saved)
    end
    return default
end

-- draws one line of text at a screen position (0.0 to 1.0 across and down).
-- call it every frame while you want it visible.
-- centered and color are optional, color looks like { 255, 220, 80 }
function FrameOS.drawText(text, x, y, scale, centered, color)
    color = color or { 255, 255, 255 }
    SetTextFont(4)
    SetTextScale(scale, scale)
    SetTextColour(color[1], color[2], color[3], 230)
    SetTextOutline()
    if centered then
        SetTextCentre(true)
    end
    BeginTextCommandDisplayText('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayText(x, y)
end

-- finds the ground under a position (the game needs the area loaded first).
-- it only looks from just above the height you give it. looking from higher
-- up finds rooftops, which is what used to drop you on top of buildings.
-- if the ground it finds isn't close to your height, you get your height back.
function FrameOS.groundZ(x, y, z)
    local found, groundZ = GetGroundZFor_3dCoord(x, y, z + 1.0, false)
    if found and math.abs(groundZ - z) < 3.0 then
        return groundZ
    end
    return z
end

-- map icons (blips). Config.showBlips = false turns all of them off.
-- sprite is the icon number and color is the icon color, from the game's blip lists.
local function nameBlip(blip, label)
    BeginTextCommandSetBlipName('STRING')
    AddTextComponentSubstringPlayerName(label)
    EndTextCommandSetBlipName(blip)
end

-- a blip at a spot on the map. returns the blip (or nil when blips are off)
function FrameOS.addBlip(x, y, z, sprite, color, label)
    if not Config.showBlips then
        return nil
    end
    local blip = AddBlipForCoord(x, y, z)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color or 0)
    SetBlipScale(blip, 0.8)
    SetBlipAsShortRange(blip, true)   -- only shows up on the minimap when you're close
    nameBlip(blip, label)
    return blip
end

-- a blip that follows a vehicle or ped around
function FrameOS.addEntityBlip(entity, sprite, color, label)
    if not Config.showBlips then
        return nil
    end
    local blip = AddBlipForEntity(entity)
    SetBlipSprite(blip, sprite)
    SetBlipColour(blip, color or 0)
    nameBlip(blip, label)
    return blip
end

-- removes every blip in a list
function FrameOS.removeBlips(list)
    for _, blip in ipairs(list) do
        if DoesBlipExist(blip) then
            RemoveBlip(blip)
        end
    end
end

-- forgets a saved value completely
function FrameOS.forget(key)
    DeleteResourceKvp('frameos_' .. key)
end

-- shows the little help text in the top left of the screen
function FrameOS.help(text)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(text)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

-- the heavy weapons (trunk = true in the config), for quick lookup
FrameOS.trunkSet = {}
for _, gun in ipairs(Config.loadout) do
    if gun.trunk and Config.trunkWeapons then
        FrameOS.trunkSet[gun.name] = true
    end
end

-- remembers your health, armor and weapons.
-- changing ped wipes all of them, so anything that changes ped takes a
-- snapshot first and restores it after.
-- skipTrunk = true leaves the trunk weapons out of the snapshot.
function FrameOS.snapshot(skipTrunk)
    local ped = PlayerPedId()
    local snap = {
        health = GetEntityHealth(ped),
        armor = GetPedArmour(ped),
        weapons = {},
    }
    for _, name in ipairs(Config.allWeapons) do
        local hash = joaat(name)
        if HasPedGotWeapon(ped, hash, false) then
            if not (skipTrunk and FrameOS.trunkSet[name]) then
                table.insert(snap.weapons, { name = name, ammo = GetAmmoInPedWeapon(ped, hash) })
            end
        end
    end
    return snap
end

-- puts a snapshot back on your ped
function FrameOS.restore(snap)
    local ped = PlayerPedId()
    -- start clean so ammo isn't added on top of what you already have
    RemoveAllPedWeapons(ped, true)
    -- never restore to near-dead health
    SetEntityHealth(ped, math.max(snap.health, 120))
    SetPedArmour(ped, snap.armor)
    for _, weapon in ipairs(snap.weapons) do
        GiveWeaponToPed(ped, joaat(weapon.name), weapon.ammo, false, false)
    end
end

-- makes a command and remembers it for the /frameos list
function FrameOS.command(name, help, fn)
    RegisterCommand(name, fn)
    table.insert(FrameOS.commandList, '/' .. name .. ' - ' .. help)
end

-- same as command, but only exists while Config.testCommands is true.
-- use it for anything that is a cheat, a teleport, a debug print or a build tool.
function FrameOS.testCommand(name, help, fn)
    if Config.testCommands then
        FrameOS.command(name, help, fn)
    end
end

-- modules use this to say "do this when I spawn in".
-- they run in the order the modules load. outfit must come before
-- basics, because changing ped model wipes your weapons.
function FrameOS.onSpawn(fn)
    table.insert(FrameOS.spawnTasks, fn)
end

-- the one spawn handler for everything
-- (this event comes from FiveM's spawnmanager)
AddEventHandler('playerSpawned', function()
    for _, task in ipairs(FrameOS.spawnTasks) do
        task()
    end
end)

FrameOS.command('frameos', 'lists every command', function()
    for _, line in ipairs(FrameOS.commandList) do
        print(line)
    end
    FrameOS.notify('Command list printed in the F8 console')
end)

-- presets: modules that save things you place (spots, safehouses, shops,
-- pickups) register a function here that returns lines of Lua for config.lua.
FrameOS.exporters = {}

function FrameOS.addExport(fn)
    table.insert(FrameOS.exporters, fn)
end

FrameOS.testCommand('exportpresets', 'turns what you placed into config lines (saved to exported_presets.lua)', function()
    local lines = { '-- paste these at the bottom of config.lua (the shop lines go in data/shops.lua instead)', '' }
    for _, fn in ipairs(FrameOS.exporters) do
        for _, line in ipairs(fn()) do
            table.insert(lines, line)
        end
        table.insert(lines, '')
    end
    local text = table.concat(lines, '\n')
    print(text)
    -- the server writes the file (see server.lua)
    TriggerServerEvent('frameos:savePresets', text)
    FrameOS.notify('Exported. Printed in F8 and saved as exported_presets.lua in the frameos folder')
end)
