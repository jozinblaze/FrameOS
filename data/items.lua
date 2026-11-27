-- items: every item the game knows about. item shops pull from this list.
-- the price here is the normal price. a shop can charge something else
-- (see data/shops.lua).
--
-- what an item can do (use as many as make sense):
--   label    the name you see
--   weight   how heavy it is (kg). the bag and every container have a weight limit (data/storage.lua)
--   price    the normal price
--   heal     health it gives when you use it (health runs 100 to 200 on most peds)
--   food     how much hunger it fills (0 to 100, see Config.needs)
--   drink    how much thirst it quenches (0 to 100)
--   armor    armor it gives when you use it (0 to 100)
--   fix      true = repairs the car you're sitting in when you use it
--   weapon   buying it gives you this weapon right away, ammo is how much comes with it
--   ammoFor  buying it adds ammo (ammo = how much) to the first of these weapons you carry
--
-- an item with none of those just sits in your bag (/inv shows it).

Items = {
    -- food and drink
    burger        = { label = 'Burger Shot Burger', price = 4,  weight = 0.4, heal = 30, food = 40 },
    cluckin_meal  = { label = "Cluckin' Bell Meal", price = 5,  weight = 0.5, heal = 35, food = 45 },
    sandwich      = { label = 'Sandwich',      price = 2,   weight = 0.3, heal = 25, food = 30 },
    water         = { label = 'Water Bottle',  price = 2,   weight = 0.5, heal = 10, drink = 35 },
    ecola         = { label = 'eCola',         price = 2,   weight = 0.4, heal = 10, drink = 25 },
    sprunk        = { label = 'Sprunk',        price = 2,   weight = 0.4, heal = 10, drink = 25 },
    candy_bar     = { label = 'Candy Bar',     price = 2,   weight = 0.1, heal = 5, food = 8 },
    coffee        = { label = 'Coffee',        price = 5,   weight = 0.3, heal = 10, drink = 15 },
    pisswasser    = { label = 'Pisswasser',    price = 7,   weight = 0.5, drink = 10 },
    whiskey       = { label = 'Whiskey',       price = 10,  weight = 0.8, drink = 5 },
    vodka         = { label = 'Vodka',         price = 12,  weight = 0.8, drink = 5 },

    -- medical and repair
    bandage           = { label = 'Bandage',             price = 100, weight = 0.1, heal = 60 },
    repairkit         = { label = 'Repair Kit',          price = 250, weight = 2.0, fix = true },
    advancedrepairkit = { label = 'Advanced Repair Kit', price = 500, weight = 3.0, fix = true },

    -- bag items with no use yet
    lighter        = { label = 'Lighter',         price = 2,    weight = 0.1 },
    lockpick       = { label = 'Lockpick',        price = 200,  weight = 0.1 },
    screwdriverset = { label = 'Screwdriver Set', price = 350,  weight = 0.5 },
    phone          = { label = 'Phone',           price = 850,  weight = 0.2 },
    radio          = { label = 'Radio',           price = 250,  weight = 0.5 },
    binoculars     = { label = 'Binoculars',      price = 50,   weight = 0.5 },
    cleaningkit    = { label = 'Cleaning Kit',    price = 150,  weight = 1.0 },
    diving_gear    = { label = 'Diving Gear',     price = 2500, weight = 8.0 },
    jerry_can      = { label = 'Jerry Can',       price = 200,  weight = 5.0 },

    -- gear you get right away
    parachute = { label = 'Parachute', price = 2500, weight = 4.0, weapon = 'GADGET_PARACHUTE', ammo = 1 },

    -- weapons you get right away
    weapon_knife         = { label = 'Knife',          price = 250,  weight = 0.5, weapon = 'WEAPON_KNIFE',         ammo = 1 },
    weapon_bat           = { label = 'Bat',            price = 250,  weight = 1.0, weapon = 'WEAPON_BAT',           ammo = 1 },
    weapon_hatchet       = { label = 'Hatchet',        price = 250,  weight = 1.5, weapon = 'WEAPON_HATCHET',       ammo = 1 },
    weapon_wrench        = { label = 'Wrench',         price = 250,  weight = 1.0, weapon = 'WEAPON_WRENCH',        ammo = 1 },
    weapon_hammer        = { label = 'Hammer',         price = 250,  weight = 1.0, weapon = 'WEAPON_HAMMER',        ammo = 1 },
    weapon_pistol        = { label = 'Pistol',         price = 2500, weight = 1.0, weapon = 'WEAPON_PISTOL',        ammo = 50 },
    weapon_snspistol     = { label = 'SNS Pistol',     price = 1500, weight = 0.8, weapon = 'WEAPON_SNSPISTOL',     ammo = 50 },
    weapon_vintagepistol = { label = 'Vintage Pistol', price = 4000, weight = 1.0, weapon = 'WEAPON_VINTAGEPISTOL', ammo = 50 },

    -- ammo (you need one of the pistols first)
    pistol_ammo = {
        label = 'Pistol Ammo', price = 250, weight = 0.5, ammo = 50,
        ammoFor = { 'WEAPON_PISTOL', 'WEAPON_SNSPISTOL', 'WEAPON_VINTAGEPISTOL' },
    },
}
