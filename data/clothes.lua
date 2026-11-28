-- clothing stores, barbers and wardrobes. the places come from your old config (15 clothing stores,
-- 7 barbers, 15 outfit changers). walk into the circle and press E. the server checks you are really there.
--
--   Config.clothesPrice    what a change at a clothing store costs (one flat price per visit, only if you changed something)
--   Config.barberPrice     the same for a barber
--   Config.wardrobeSlots   how many outfits you can keep in a wardrobe (saving one is free)
--   a store can have its own price: add  price = 300  to its line.
--   wardrobes are at the spots below and at every safehouse (press H there).
-- the lists of what you can change are Config.clothesSlots (clothing store) and, for the barber, the
-- overlay list in data/character.lua.

Config.clothesPrice = 150
Config.barberPrice = 60
Config.wardrobeSlots = 5

-- what a barber can change (the overlay numbers from data/character.lua): facial hair, eyebrows,
-- makeup, blush, lipstick, chest hair. hair style, hair color and eye color are always included.
-- the face shape, skin and the rest stay creator only.
Config.barberOverlays = { 1, 2, 4, 5, 8, 10 }

-- map icons (73 is the clothes hanger, 71 is the scissors)
Config.clothesBlip = { sprite = 73, color = 0 }
Config.barberBlip = { sprite = 71, color = 0 }

-- what the clothing store lets you change. kind 'part' is a clothing slot, 'prop' is something you put on.
-- the numbers are the game's slot numbers (the same ones /clothinfo prints).
Config.clothesSlots = {
    { kind = 'prop', id = 0,  name = 'Hat' },
    { kind = 'prop', id = 1,  name = 'Glasses' },
    { kind = 'prop', id = 2,  name = 'Ear piece' },
    { kind = 'part', id = 1,  name = 'Mask' },
    { kind = 'part', id = 11, name = 'Top' },
    { kind = 'part', id = 8,  name = 'Undershirt' },
    { kind = 'part', id = 3,  name = 'Arms (match them to your top)' },
    { kind = 'part', id = 4,  name = 'Legs' },
    { kind = 'part', id = 6,  name = 'Shoes' },
    { kind = 'part', id = 7,  name = 'Neck' },
    { kind = 'part', id = 5,  name = 'Bag' },
    { kind = 'prop', id = 6,  name = 'Watch' },
    { kind = 'prop', id = 7,  name = 'Bracelet' },
}

Config.clothingStores = {
    { label = 'Clothing store', x = 1693.32, y = 4823.48, z = 41.06 },
    { label = 'Clothing store', x = -712.22, y = -155.35, z = 37.42 },
    { label = 'Clothing store', x = -1192.94, y = -772.69, z = 17.33 },
    { label = 'Clothing store', x = 425.24, y = -806.01, z = 28.49 },
    { label = 'Clothing store', x = -162.66, y = -303.4, z = 38.73 },
    { label = 'Clothing store', x = 75.95, y = -1392.89, z = 28.38 },
    { label = 'Clothing store', x = -822.19, y = -1074.13, z = 10.33 },
    { label = 'Clothing store', x = -1450.71, y = -236.83, z = 48.81 },
    { label = 'Clothing store', x = 4.25, y = 6512.81, z = 30.88 },
    { label = 'Clothing store', x = 615.18, y = 2762.93, z = 41.09 },
    { label = 'Clothing store', x = 1196.79, y = 2709.56, z = 37.22 },
    { label = 'Clothing store', x = -3171.45, y = 1043.86, z = 19.86 },
    { label = 'Clothing store', x = -1100.96, y = 2710.21, z = 18.11 },
    { label = 'Clothing store', x = -1207.65, y = -1456.88, z = 4.38 },
    { label = 'Clothing store', x = 121.76, y = -224.6, z = 53.56 },
}

Config.barbers = {
    { label = 'Barber', x = -814.3, y = -183.8, z = 36.6 },
    { label = 'Barber', x = 136.8, y = -1708.4, z = 28.3 },
    { label = 'Barber', x = -1282.6, y = -1116.8, z = 6.0 },
    { label = 'Barber', x = 1931.5, y = 3729.7, z = 31.8 },
    { label = 'Barber', x = 1212.8, y = -472.9, z = 65.2 },
    { label = 'Barber', x = -32.9, y = -152.3, z = 56.1 },
    { label = 'Barber', x = -278.1, y = 6228.5, z = 30.7 },
}

Config.wardrobes = {
    { label = 'Wardrobe', x = 1697.41, y = 4829.25, z = 41.06 },
    { label = 'Wardrobe', x = -703.83, y = -151.67, z = 36.42 },
    { label = 'Wardrobe', x = -1187.19, y = -768.64, z = 16.33 },
    { label = 'Wardrobe', x = 429.5, y = -800.15, z = 28.49 },
    { label = 'Wardrobe', x = -168.21, y = -298.7, z = 38.73 },
    { label = 'Wardrobe', x = 71.06, y = -1399.17, z = 28.38 },
    { label = 'Wardrobe', x = -829.72, y = -1073.33, z = 10.33 },
    { label = 'Wardrobe', x = -1447.51, y = -242.81, z = 48.82 },
    { label = 'Wardrobe', x = 12.28, y = 6513.63, z = 30.88 },
    { label = 'Wardrobe', x = 617.89, y = 2766.79, z = 41.09 },
    { label = 'Wardrobe', x = 1190.35, y = 2714.51, z = 37.22 },
    { label = 'Wardrobe', x = -3175.64, y = 1041.84, z = 19.86 },
    { label = 'Wardrobe', x = -1108.95, y = 2709.37, z = 18.11 },
    { label = 'Wardrobe', x = -1203.79, y = -1454.53, z = 3.38 },
    { label = 'Wardrobe', x = 120.44, y = -227.38, z = 53.56 },
}
