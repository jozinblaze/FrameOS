-- ipl: loads map pieces (IPLs) in one place when you start.
-- fill in Config.ipls and Config.removeIpls in config.lua.
-- /ipl                  shows the game build this server is running
-- /ipl <name>           says whether that IPL is loaded right now
-- /ipl <name> on|off    loads or unloads it, so you can test names in game

CreateThread(function()
    -- give the game a moment to finish loading the map first
    Wait(1000)

    -- unload the clashing ones first
    for _, name in ipairs(Config.removeIpls) do
        RemoveIpl(name)
    end

    -- then load yours, skipping any that need a newer game build
    for _, ipl in ipairs(Config.ipls) do
        if not ipl.build or GetGameBuildNumber() >= ipl.build then
            RequestIpl(ipl.name)
        else
            print('[FrameOS] skipped IPL ' .. ipl.name .. ' (needs build ' .. ipl.build .. ')')
        end
    end

    print('[FrameOS] game build ' .. GetGameBuildNumber())
end)

FrameOS.testCommand('ipl', 'IPL tools: /ipl, /ipl <name>, /ipl <name> on|off', function(source, args)
    if not args[1] then
        FrameOS.notify('Game build ' .. GetGameBuildNumber())
        return
    end

    local name = args[1]
    if args[2] == 'on' then
        RequestIpl(name)
        FrameOS.notify('Requested IPL ' .. name)
    elseif args[2] == 'off' then
        RemoveIpl(name)
        FrameOS.notify('Removed IPL ' .. name)
    elseif IsIplActive(name) then
        FrameOS.notify(name .. ' is loaded')
    else
        FrameOS.notify(name .. ' is NOT loaded')
    end
end)
