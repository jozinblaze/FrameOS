-- storage: how much things can hold. weights are in kg and match the weights in data/items.lua.
--
-- Config.bagWeight       what your bag can carry
-- Config.gloveboxWeight  every owned car has a glovebox this big
-- Config.stashWeight     every safehouse has a stash this big
-- Config.trunkWeights    trunk size by vehicle category (the category written in data/vehicles.lua)
--                        0 means no trunk (bikes). a category not listed uses Config.trunkDefault.
--
-- only cars you own have storage (it is kept by the car's plate, in your save file).
-- the server checks all of this, so changing a number here changes it for everyone.

Config.bagWeight = 30
Config.gloveboxWeight = 5
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
}

-- the trunk size for a car model (0 = no trunk). both sides use this.
function Config.trunkCapacity(model)
    local info = Vehicles[model]
    local size = info and info.category and Config.trunkWeights[info.category]
    if size == nil then
        size = Config.trunkDefault
    end
    return size
end
