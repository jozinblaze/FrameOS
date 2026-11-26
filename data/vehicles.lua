-- vehicles: every car the dealerships can sell. vehicle shops pull from this list.
-- the key is the game's model name (what /car uses). prices are my rough guesses,
-- change them however you like. models your game build doesn't have are skipped
-- in the shop, so it's safe to add newer cars.
--
--   name      what the shop shows
--   price     what it costs
--   category  shown next to the name

Vehicles = {
    -- compacts
    panto   = { name = 'Panto',    price = 6000,   category = 'Compacts' },
    issi2   = { name = 'Issi',     price = 9000,   category = 'Compacts' },
    blista  = { name = 'Blista',   price = 12000,  category = 'Compacts' },

    -- sedans
    asea      = { name = 'Asea',      price = 12000, category = 'Sedans' },
    premier   = { name = 'Premier',   price = 15000, category = 'Sedans' },
    fugitive  = { name = 'Fugitive',  price = 24000, category = 'Sedans' },
    tailgater = { name = 'Tailgater', price = 55000, category = 'Sedans' },
    schafter2 = { name = 'Schafter',  price = 65000, category = 'Sedans' },

    -- coupes
    sentinel = { name = 'Sentinel', price = 45000, category = 'Coupes' },
    felon2   = { name = 'Felon GT', price = 55000, category = 'Coupes' },
    zion     = { name = 'Zion',     price = 60000, category = 'Coupes' },
    jackal   = { name = 'Jackal',   price = 60000, category = 'Coupes' },
    oracle2  = { name = 'Oracle XS', price = 80000, category = 'Coupes' },

    -- muscle
    sabregt   = { name = 'Sabre Turbo', price = 15000, category = 'Muscle' },
    ruiner    = { name = 'Ruiner',      price = 20000, category = 'Muscle' },
    vigero    = { name = 'Vigero',      price = 21000, category = 'Muscle' },
    buccaneer = { name = 'Buccaneer',   price = 29000, category = 'Muscle' },
    ellie     = { name = 'Ellie',      price = 50000, category = 'Muscle' },
    gauntlet  = { name = 'Gauntlet',    price = 32000, category = 'Muscle' },
    dominator = { name = 'Dominator',   price = 35000, category = 'Muscle' },

    -- sports
    futo        = { name = 'Futo',       price = 14000,  category = 'Sports' },
    sultan      = { name = 'Sultan',     price = 22000,  category = 'Sports' },
    buffalo     = { name = 'Buffalo',    price = 35000,  category = 'Sports' },
    comet2      = { name = 'Comet',      price = 75000,  category = 'Sports' },
    banshee     = { name = 'Banshee',    price = 95000,  category = 'Sports' },
    elegy2      = { name = 'Elegy RH8',  price = 95000,  category = 'Sports' },
    kuruma      = { name = 'Kuruma',     price = 95000,  category = 'Sports' },
    surano      = { name = 'Surano',     price = 110000, category = 'Sports' },
    carbonizzare = { name = 'Carbonizzare', price = 195000, category = 'Sports' },
    jester      = { name = 'Jester',     price = 240000, category = 'Sports' },
    massacro    = { name = 'Massacro',   price = 275000, category = 'Sports' },

    -- sports classics
    monroe    = { name = 'Monroe',            price = 490000, category = 'Sports Classics' },
    coquette2 = { name = 'Coquette Classic',  price = 665000, category = 'Sports Classics' },
    btype     = { name = 'Roosevelt',         price = 750000, category = 'Sports Classics' },
    stinger   = { name = 'Stinger',           price = 850000, category = 'Sports Classics' },
    ztype     = { name = 'Z-Type',            price = 950000, category = 'Sports Classics' },

    -- super
    vacca    = { name = 'Vacca',    price = 240000,  category = 'Super' },
    infernus = { name = 'Infernus', price = 440000,  category = 'Super' },
    turismor = { name = 'Turismo R', price = 500000, category = 'Super' },
    cheetah  = { name = 'Cheetah',  price = 650000,  category = 'Super' },
    zentorno = { name = 'Zentorno', price = 725000,  category = 'Super' },
    entityxf = { name = 'Entity XF', price = 795000, category = 'Super' },
    adder    = { name = 'Adder',    price = 1000000, category = 'Super' },
    pfister811 = { name = '811',    price = 1135000, category = 'Super' },
    italigtb = { name = 'Itali GTB', price = 1189000, category = 'Super' },
    tempesta = { name = 'Tempesta', price = 1329000, category = 'Super' },
    nero     = { name = 'Nero',     price = 1440000, category = 'Super' },
    reaper   = { name = 'Reaper',   price = 1595000, category = 'Super' },
    fmj      = { name = 'FMJ',      price = 1750000, category = 'Super' },
    osiris   = { name = 'Osiris',   price = 1950000, category = 'Super' },
    t20      = { name = 'T20',      price = 2200000, category = 'Super' },
    italirsx = { name = 'Itali RSX', price = 3000000, category = 'Super' },

    -- suvs
    granger    = { name = 'Granger',    price = 35000, category = 'SUVs' },
    landstalker = { name = 'Landstalker', price = 58000, category = 'SUVs' },
    baller     = { name = 'Baller',     price = 90000, category = 'SUVs' },

    -- offroad
    bfinjection = { name = 'BF Injection', price = 16000, category = 'Offroad' },
    rebel       = { name = 'Rebel',        price = 22000, category = 'Offroad' },
    sandking    = { name = 'Sandking XL',  price = 38000, category = 'Offroad' },

    -- vans and trucks
    rumpo  = { name = 'Rumpo',  price = 13000, category = 'Vans' },
    speedo = { name = 'Speedo', price = 20000, category = 'Vans' },
    bison  = { name = 'Bison',  price = 30000, category = 'Vans' },

    -- motorcycles
    faggio  = { name = 'Faggio',   price = 4000,  category = 'Motorcycles' },
    sanchez = { name = 'Sanchez',  price = 8000,  category = 'Motorcycles' },
    akuma   = { name = 'Akuma',    price = 9000,  category = 'Motorcycles' },
    pcj     = { name = 'PCJ 600',  price = 9000,  category = 'Motorcycles' },
    bati    = { name = 'Bati 801', price = 15000, category = 'Motorcycles' },
    hexer   = { name = 'Hexer',    price = 15000, category = 'Motorcycles' },

    -- bicycles
    cruiser  = { name = 'Cruiser',  price = 300, category = 'Bicycles' },
    scorcher = { name = 'Scorcher', price = 400, category = 'Bicycles' },
    bmx      = { name = 'BMX',      price = 500, category = 'Bicycles' },
    tribike  = { name = 'Whippet Race Bike', price = 700, category = 'Bicycles' },
}
