-- storage: how much things can hold. weights are in kg and match the weights in data/items.lua.
--
-- Config.bagWeight       what you can carry with no bag on
-- Config.bags            the bags that carry more (see below)
-- Config.gloveboxWeight  the glovebox of a car (see gloveboxWeights below for exceptions)
-- Config.stashWeight     every safehouse has a stash this big
-- Config.trunkWeights    trunk size by vehicle category (the category written in data/vehicles.lua)
--                        0 means no trunk (bikes). a category not listed uses Config.trunkDefault.
--
-- only cars you own have storage (it is kept by the car's plate, in your save file).
-- the server checks all of this, so changing a number here changes it for everyone.

Config.bagWeight = 20

-- wearing one of these bags (clothing slot 5) adds to what you can carry. the key is the bag's drawable
-- number (use /clothinfo to see the number of the bag you are wearing). extra = kg added, price = what it
-- costs on top of the clothing store price when you buy it, name = what the store shows.
-- THESE NUMBERS ARE PLACEHOLDERS: swap in the bag numbers you want. any other bag is only for looks.
-- the server works the limit out from the bag saved on your character, so it cannot be faked.
Config.bags = {
    [40] = { name = 'Small bag',    extra = 10, price = 100 },
    [41] = { name = 'Duffel bag',   extra = 20, price = 250 },
    [44] = { name = 'Backpack',     extra = 30, price = 400 },
    [45] = { name = 'Big backpack', extra = 45, price = 700 },
    -- added after testing 1.11.0 (still guesses for kg and price, rename and adjust)
    [81] = { name = 'Bag 81',       extra = 15, price = 150 },
    [82] = { name = 'Bag 82',       extra = 15, price = 150 },
    [85] = { name = 'Bag 85',       extra = 25, price = 300 },
    [86] = { name = 'Bag 86',       extra = 25, price = 300 },
}
Config.gloveboxWeight = 5

-- gloveboxes by vehicle category. 0 means no glovebox (bikes). a category not listed uses gloveboxWeight.
Config.gloveboxWeights = {
    Bicycles = 0,
    Motorcycles = 0,
    Super = 3,
    Vans = 8,
    Commercial = 10,
}
Config.stashWeight = 100

Config.trunkDefault = 30
Config.trunkWeights = {
    Bicycles = 0,
    Motorcycles = 0,
    Compacts = 25,
    Coupes = 30,
    Sedans = 40,
    Muscle = 35,
    Sports = 25,
    ['Sports Classics'] = 30,
    Super = 15,
    SUVs = 80,
    Offroad = 60,
    Vans = 100,
    -- work vehicles: use these category names in data/vehicles.lua when you add trucks to a showroom
    Utility = 120,
    Commercial = 200,
    Industrial = 300,
}

-- one model that should not follow its category (model name -> kg, 0 = no trunk). examples:
--   Config.trunkByModel = { bison = 150, rumpo = 160 }
Config.trunkByModel = {}
Config.gloveboxByModel = {}


-- the trunk size for a car model (0 = no trunk). both sides use this.
function Config.trunkCapacity(model)
    if Config.trunkByModel[model] ~= nil then
        return Config.trunkByModel[model]
    end
    local info = Vehicles[model]
    local size = info and info.category and Config.trunkWeights[info.category]
    if size == nil then
        size = Config.trunkDefault
    end
    return size
end

-- the glovebox size for a car model (0 = no glovebox). both sides use this.
function Config.gloveboxCapacity(model)
    if Config.gloveboxByModel[model] ~= nil then
        return Config.gloveboxByModel[model]
    end
    local info = Vehicles[model]
    local size = info and info.category and Config.gloveboxWeights[info.category]
    if size == nil then
        size = Config.gloveboxWeight
    end
    return size
end
