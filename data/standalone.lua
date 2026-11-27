-- Standalone quality-of-life systems built for FrameOS.
-- No framework bridge or third-party runtime dependency is used.

Config.afk = {
    enabled = true,
    timeout = 1800,          -- seconds without client input before removal
    warningAt = { 300, 60 }, -- seconds remaining
    checkEvery = 15,         -- activity heartbeat interval in seconds
}

Config.population = {
    disableRandomCops = true,
    disableGarbageTrucks = true,
    disableRandomBoats = false,
    disableWanted = false,
    maxWantedLevel = 5,
    dispatch = {
        [1] = false, [2] = false, [3] = false, [4] = false, [5] = false,
        [6] = false, [7] = false, [8] = true,  [9] = false, [10] = false,
        [11] = false, [12] = false, [13] = false, [14] = false, [15] = false,
    },
    disabledScenarioTypes = {
        'WORLD_VEHICLE_AMBULANCE', 'WORLD_VEHICLE_FIRE_TRUCK',
        'WORLD_VEHICLE_POLICE_BIKE', 'WORLD_VEHICLE_POLICE_CAR',
        'WORLD_VEHICLE_POLICE', 'WORLD_VEHICLE_POLICE_NEXT_TO_CAR',
        'WORLD_VEHICLE_SECURITY_CAR', 'WORLD_VEHICLE_HELI_LIFEGUARD',
        'WORLD_VEHICLE_MILITARY_PLANES_BIG', 'WORLD_VEHICLE_MILITARY_PLANES_SMALL',
    },
    suppressedVehicleModels = {
        'SHAMAL', 'LUXOR', 'LUXOR2', 'JET', 'LAZER', 'TITAN',
        'CRUSADER', 'RHINO', 'AIRTUG', 'RIPLEY', 'BLIMP',
    },
    disabledScenarioGroups = {},
    noAmbientHeadshots = false,
    disableIdleCamera = true,
    disableAmbience = false,
}

Config.utilityControls = {
    crouch = 'K',
    cruise = 'Y',
    flipVehicle = 'U',
    pushVehicle = 'H',
    tackle = 'F6',
    toggleRadio = 'F9',
    editor = 'F5',
}

Config.vehicleUtilities = {
    cruiseClasses = { 0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 17, 18, 19, 20 },
    pushEngineHealth = 1000.0,
    pushDistance = 3.0,
    pushBlacklistedClasses = { 13, 14, 15, 16, 21 },
    flipDistance = 3.0,
    flipDuration = 5000,
}

Config.weaponUtilities = {
    disableWorldWeaponPickups = true,
    disableWeaponWheel = true,
    hideReticle = false,
    disablePistolWhip = false,
    infiniteUtilityAmmo = false,
    extendStun = true,
    stunTime = { min = 4000, max = 7000 },
    recoil = {
        WEAPON_PISTOL = 0.35,
        WEAPON_COMBATPISTOL = 0.30,
        WEAPON_SNSPISTOL = 0.40,
        WEAPON_VINTAGEPISTOL = 0.35,
        WEAPON_MICROSMG = 0.25,
        WEAPON_SMG = 0.20,
        WEAPON_PUMPSHOTGUN = 0.60,
        WEAPON_ASSAULTRIFLE = 0.30,
        WEAPON_CARBINERIFLE = 0.25,
        WEAPON_SNIPERRIFLE = 0.80,
    },
}

Config.entityRestrictions = {
    -- Add model names here to reject them before they enter the OneSync world.
    blockedModels = {},
}

Config.removedWorldObjects = {
    -- Optional objects: { model = 'prop_name', x = 0.0, y = 0.0, z = 0.0, radius = 2.0 }
}

Config.teleportGroups = {
    -- Add MLO-specific elevators as groups of stops. Coordinates are intentionally
    -- left empty because interiors depend on the server's installed map assets.
    -- Example: { label = 'Office', stops = { { label = 'Lobby', x = 1, y = 2, z = 3 } } }
}

Config.staticEmitterSettings = {
    enabled = false,
    emitters = {},
    disable = {},
}
