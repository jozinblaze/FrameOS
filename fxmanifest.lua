fx_version 'cerulean'
game 'gta5'

-- load order matters: config, the data lists and core first, then the modules.
-- to add a module, put a file in modules/ and add a line here.
-- (outfit comes before basics on purpose, see the spawn note in core.lua)
server_script 'server.lua'

client_scripts {
    'config.lua',
    'data/items.lua',
    'data/vehicles.lua',
    'data/shops.lua',
    'data/jobs.lua',
    'core.lua',
    'modules/world.lua',
    'modules/hud.lua',
    'modules/outfit.lua',
    'modules/spots.lua',
    'modules/garage.lua',
    'modules/basics.lua',
    'modules/cash.lua',        -- cash must load before pickups and safehouses
    'modules/pickups.lua',
    'modules/safehouses.lua',
    'modules/vehicles.lua',
    'modules/inventory.lua',   -- inventory must load before the shop
    'modules/jobs.lua',        -- the job engine, job files come right after it
    'modules/jobs/courier.lua',
    'modules/jobs/pimp.lua',
    'modules/shop.lua',
    'modules/trunk.lua',
    'modules/death.lua',
    'modules/ipl.lua',
    'modules/state.lua',       -- state must stay last, it restores everything on spawn
}
