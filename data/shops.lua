-- shops: what each kind of shop sells, and where the shops are.
--
-- there are two kinds of shop:
--   'items'    pulls from data/items.lua    (stores, ammunation, hardware...)
--   'vehicles' pulls from data/vehicles.lua (car dealerships)
--
-- Config.stock  named lists of what a shop sells. a shop picks one by name.
--               an item can also be written { name = 'pisswasser', price = 9 } to
--               charge a different price at that shop.
-- Config.shops  the shops themselves:
--   label   the name shown on the map and in the shop
--   type    'items' or 'vehicles'
--   stock   which list from Config.stock it sells
--   x, y, z where you stand to browse
--   blip    { sprite = , color = } the map icon (optional, there are defaults)
--   vehicle shops can also have:
--     spawn   { x, y, z, h }  where a car you buy appears (otherwise next to you)
--     preview { x, y, z, h }  where the car on display stands (otherwise 6 meters ahead)
--
-- shops you make in game with /setshop are saved on your PC. /exportpresets
-- prints them as lines you can paste at the bottom of this file.
-- the places below come from the shop and vehicleshop configs you shared.

Config.stock = {
    -- item lists
    normal = {
        'burger', 'cluckin_meal', 'sandwich', 'water', 'ecola', 'sprunk', 'candy_bar',
        'pisswasser', 'whiskey', 'vodka', 'bandage', 'lighter',
    },
    hardware = {
        'lockpick', 'weapon_wrench', 'weapon_hammer', 'repairkit', 'screwdriverset',
        'phone', 'radio', 'binoculars', 'cleaningkit',
    },
    weapons = {
        'weapon_knife', 'weapon_bat', 'weapon_hatchet', 'weapon_pistol',
        'weapon_snspistol', 'weapon_vintagepistol', 'pistol_ammo',
    },
    coffee  = { 'coffee', 'lighter' },
    gear    = { 'diving_gear', 'jerry_can' },
    leisure = { 'parachute', 'binoculars', 'diving_gear' },

    -- vehicle lists
    dealership = { 'faggio', 'issi2', 'futo', 'sultan', 'buffalo', 'felon2', 'comet2', 'bati', 'banshee' },
    pdm = {
        'panto', 'issi2', 'blista', 'asea', 'premier', 'fugitive', 'tailgater', 'schafter2',
        'sentinel', 'felon2', 'zion', 'jackal', 'sabregt', 'ruiner', 'vigero', 'buccaneer',
        'gauntlet', 'dominator', 'futo', 'sultan', 'buffalo', 'comet2', 'banshee', 'elegy2',
        'kuruma', 'surano', 'monroe', 'coquette2', 'granger', 'landstalker', 'baller',
        'bfinjection', 'rebel', 'sandking', 'rumpo', 'speedo', 'bison', 'faggio', 'sanchez',
        'akuma', 'pcj', 'bati', 'hexer', 'cruiser', 'scorcher', 'bmx', 'tribike',
    },
    exotic = {
        'vacca', 'infernus', 'turismor', 'cheetah', 'zentorno', 'entityxf', 'adder',
        'pfister811', 'italigtb', 'tempesta', 'nero', 'reaper', 'fmj', 'osiris', 't20',
        'italirsx', 'carbonizzare', 'jester', 'massacro', 'btype', 'stinger', 'ztype',
    },
}

Config.shops = {}

-- small helper so each store below fits on one line.
-- the sprite and color are the map icon.
local function store(id, label, stock, x, y, z, sprite, color)
    Config.shops[id] = {
        label = label, type = 'items', stock = stock,
        x = x, y = y, z = z,
        blip = { sprite = sprite, color = color },
    }
end

-- 24/7 supermarkets
store('247_1',  '24/7 Supermarket', 'normal', 25.7,     -1347.3,  29.49, 52, 2)
store('247_2',  '24/7 Supermarket', 'normal', -3038.71, 585.9,    7.9,   52, 2)
store('247_3',  '24/7 Supermarket', 'normal', -3241.47, 1001.14,  12.83, 52, 2)
store('247_4',  '24/7 Supermarket', 'normal', 1728.66,  6414.16,  35.03, 52, 2)
store('247_5',  '24/7 Supermarket', 'normal', 1697.99,  4924.4,   42.06, 52, 2)
store('247_6',  '24/7 Supermarket', 'normal', 1961.48,  3739.96,  32.34, 52, 2)
store('247_7',  '24/7 Supermarket', 'normal', 547.79,   2671.79,  42.15, 52, 2)
store('247_8',  '24/7 Supermarket', 'normal', 2679.25,  3280.12,  55.24, 52, 2)
store('247_9',  '24/7 Supermarket', 'normal', 2557.94,  382.05,   108.62, 52, 2)
store('247_10', '24/7 Supermarket', 'normal', 373.55,   325.56,   103.56, 52, 2)

-- LTD gasoline
store('ltd_1', 'LTD Gasoline', 'normal', -48.44,   -1757.86, 29.42,  52, 2)
store('ltd_2', 'LTD Gasoline', 'normal', -707.41,  -912.83,  19.21,  52, 2)
store('ltd_3', 'LTD Gasoline', 'normal', -1820.33, 792.66,   138.1,  52, 2)
store('ltd_4', 'LTD Gasoline', 'normal', 1163.7,   -323.92,  69.2,   52, 2)

-- Rob's Liquor
store('robs_1', "Rob's Liquor", 'normal', -1222.77, -907.19, 12.32, 52, 2)
store('robs_2', "Rob's Liquor", 'normal', -1487.7,  -378.53, 40.16, 52, 2)
store('robs_3', "Rob's Liquor", 'normal', -2967.79, 391.64,  15.04, 52, 2)
store('robs_4', "Rob's Liquor", 'normal', 1165.28,  2709.4,  38.15, 52, 2)
store('robs_5', "Rob's Liquor", 'normal', 1135.66,  -982.76, 46.41, 52, 2)

-- local stores
store('delvecchio', 'Del Vecchio Liquor',  'normal', -159.36, 6321.59, 31.58, 52, 2)
store('dons',       "Don's Country Store", 'normal', 161.41,  6640.78, 31.69, 52, 2)

-- hardware stores
store('hardware_1', 'Hardware Store', 'hardware', 45.55,   -1749.01, 29.6,  402, 5)
store('hardware_2', 'Hardware Store', 'hardware', 2747.8,  3472.86,  55.67, 402, 5)
store('hardware_3', 'Hardware Store', 'hardware', -421.84, 6136.09,  31.78, 402, 5)

-- ammunation
store('ammu_1', 'Ammunation', 'weapons', -662.1,  -935.3,   21.8,  110, 1)
store('ammu_2', 'Ammunation', 'weapons', 810.2,   -2157.3,  29.6,  110, 1)
store('ammu_3', 'Ammunation', 'weapons', 1693.4,  3759.5,   34.7,  110, 1)
store('ammu_4', 'Ammunation', 'weapons', -330.2,  6083.8,   31.4,  110, 1)
store('ammu_5', 'Ammunation', 'weapons', 252.3,   -50.0,    69.9,  110, 1)
store('ammu_6', 'Ammunation', 'weapons', 22.0,    -1107.2,  29.8,  110, 1)
store('ammu_7', 'Ammunation', 'weapons', 2567.6,  294.3,    108.7, 110, 1)
store('ammu_8', 'Ammunation', 'weapons', -1117.5, 2698.6,   18.5,  110, 1)
store('ammu_9', 'Ammunation', 'weapons', 842.4,   -1033.4,  28.1,  110, 1)

-- coffee, gear and leisure
store('bean',     'Bean Machine Coffee', 'coffee',  -633.72,  236.15,  81.88,  52, 2)
store('seaword',  'Sea Word',            'gear',    -1686.9,  -1072.23, 13.15, 52, 2)
store('leisure',  'Leisure Shop',        'leisure', -1505.91, 1511.78, 115.29, 52, 2)

-- car dealerships
Config.shops.pdm = {
    label = 'Premium Deluxe Motorsport', type = 'vehicles', stock = 'pdm',
    x = -45.67, y = -1098.34, z = 26.42,
    spawn   = { x = -56.79, y = -1109.85, z = 26.43, h = 71.5 },
    preview = { x = -47.84, y = -1091.92, z = 27.3,  h = 244.56 },
    blip = { sprite = 326, color = 3 },
}

Config.shops.exotic = {
    label = 'Exotic Vehicle Shop', type = 'vehicles', stock = 'exotic',
    x = -1255.6, y = -361.16, z = 36.91,
    spawn   = { x = -1231.46, y = -349.86, z = 37.33, h = 26.61 },
    preview = { x = -1265.31, y = -354.44, z = 35.91, h = 205.08 },
    blip = { sprite = 326, color = 3 },
}
