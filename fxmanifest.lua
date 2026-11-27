fx_version 'cerulean'
game 'gta5'

-- load order matters. to add a client module, put a file in modules/ and add a line here.
-- (outfit comes before basics on purpose, see the spawn note in core.lua)

-- these load on BOTH sides, so the server can check real prices and settings
shared_scripts {
    'config.lua',
    'data/items.lua',
    'data/vehicles.lua',
    'data/shops.lua',
    'data/jobs.lua',
    'data/banks.lua',
    'data/storage.lua',
}

-- the server side. server/core.lua must come first.
server_scripts {
    'server/core.lua',
    'server/store.lua',        -- how saved data is read and written, right after core
    'server/needs.lua',
    'server/economy.lua',
    'server/storage.lua',
    'server.lua',
}

client_scripts {
    'core.lua',
    'modules/link.lua',        -- talking to the server, right after core
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
    'modules/bank.lua',
    'modules/inventory.lua',   -- inventory must load before the shop
    'modules/storage.lua',     -- trunks, gloveboxes and stashes (uses the bag)
    'modules/needs.lua',       -- hunger and thirst (uses the bag, so it comes after it)
    'modules/jobs.lua',        -- the job engine, job files come right after it
    'modules/jobs/courier.lua',
    'modules/jobs/pimp.lua',
    'modules/shop.lua',
    'modules/trunk.lua',
    'modules/death.lua',
    'modules/ipl.lua',
    'modules/state.lua',       -- state must stay last, it restores everything on spawn
}
