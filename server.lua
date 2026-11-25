-- server: for now the server only does one thing,
-- it saves the text from /exportpresets into a file in this resource's folder.

RegisterNetEvent('frameos:savePresets', function(text)
    local player = source

    -- only admins can write files (the "command" permission in server.cfg)
    if not IsPlayerAceAllowed(player, 'command') then
        print('[FrameOS] ' .. GetPlayerName(player) .. ' tried to export presets without permission')
        return
    end

    SaveResourceFile(GetCurrentResourceName(), 'exported_presets.lua', text, -1)
    print('[FrameOS] saved exported_presets.lua')
end)
