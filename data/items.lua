-- items: every item the game knows about. item shops pull from this list.
-- the price here is the normal price. a shop can charge something else
-- (see data/shops.lua).
--
-- what an item can do (use as many as make sense):
--   label    the name you see
--   price    the normal price
--   heal     health it gives when you use it (health runs 100 to 200 on most peds)
--   armor    armor it gives when you use it (0 to 100)
--   fix      true = repairs the car you're sitting in when you use it
--   weapon   buying it gives you this weapon right away, ammo is how much comes with it
--   ammoFor  buying it adds ammo (ammo = how much) to the first of these weapons you carry
--
-- an item with none of those just sits in your bag (/inv shows it).

Items = {
    -- food and drink
    tosti         = { label = 'Tosti',         price = 2,   heal = 20 },
    sandwich      = { label = 'Sandwich',      price = 2,   heal = 25 },
    water_bottle  = { label = 'Water Bottle',  price = 2,   heal = 10 },
    kurkakola     = { label = 'Kurkakola',     price = 2,   heal = 10 },
    twerks_candy  = { label = 'Twerks Candy',  price = 2,   heal = 5 },
    snikkel_candy = { label = 'Snikkel Candy', price = 2,   heal = 5 },
    coffee        = { label = 'Coffee',        price = 5,   heal = 10 },
    beer          = { label = 'Beer',          price = 7 },
    whiskey       = { label = 'Whiskey',       price = 10 },
    vodka         = { label = 'Vodka',         price = 12 },

    -- medical and repair
    bandage           = { label = 'Bandage',             price = 100, heal = 60 },
    repairkit         = { label = 'Repair Kit',          price = 250, fix = true },
    advancedrepairkit = { label = 'Advanced Repair Kit', price = 500, fix = true },

    -- bag items with no use yet
    lighter        = { label = 'Lighter',         price = 2 },
    lockpick       = { label = 'Lockpick',        price = 200 },
    screwdriverset = { label = 'Screwdriver Set', price = 350 },
    phone          = { label = 'Phone',           price = 850 },
    radio          = { label = 'Radio',           price = 250 },
    binoculars     = { label = 'Binoculars',      price = 50 },
    fitbit         = { label = 'Fitbit',          price = 400 },
    cleaningkit    = { label = 'Cleaning Kit',    price = 150 },
    diving_gear    = { label = 'Diving Gear',     price = 2500 },
    jerry_can      = { label = 'Jerry Can',       price = 200 },

    -- gear you get right away
    parachute = { label = 'Parachute', price = 2500, weapon = 'GADGET_PARACHUTE', ammo = 1 },

    -- weapons you get right away
    weapon_knife        = { label = 'Knife',        price = 250,  weapon = 'WEAPON_KNIFE',        ammo = 1 },
    weapon_bat          = { label = 'Bat',          price = 250,  weapon = 'WEAPON_BAT',          ammo = 1 },
    weapon_hatchet      = { label = 'Hatchet',      price = 250,  weapon = 'WEAPON_HATCHET',      ammo = 1 },
    weapon_wrench       = { label = 'Wrench',       price = 250,  weapon = 'WEAPON_WRENCH',       ammo = 1 },
    weapon_hammer       = { label = 'Hammer',       price = 250,  weapon = 'WEAPON_HAMMER',       ammo = 1 },
    weapon_pistol       = { label = 'Pistol',       price = 2500, weapon = 'WEAPON_PISTOL',       ammo = 50 },
    weapon_snspistol    = { label = 'SNS Pistol',   price = 1500, weapon = 'WEAPON_SNSPISTOL',    ammo = 50 },
    weapon_vintagepistol = { label = 'Vintage Pistol', price = 4000, weapon = 'WEAPON_VINTAGEPISTOL', ammo = 50 },

    -- ammo (you need one of the pistols first)
    pistol_ammo = {
        label = 'Pistol Ammo', price = 250, ammo = 50,
        ammoFor = { 'WEAPON_PISTOL', 'WEAPON_SNSPISTOL', 'WEAPON_VINTAGEPISTOL' },
    },
}
