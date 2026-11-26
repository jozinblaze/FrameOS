-- banks and ATMs.
--
-- Config.banks         the 8 bank counters. walk into the circle and press E.
--                      you can deposit and withdraw any amount at a bank.
-- Config.atmModels     the ATM props in the world. stand at one and press E.
--                      ATMs use the same account, but you can only take out
--                      Config.atmDailyLimit a day (putting money in has no limit).
-- Config.atmDailyLimit how much cash you can take from ATMs per day (server date).
-- Config.bankBlip      the map icon for banks (sprite 108 is the dollar sign)
-- Config.bankAmounts   the quick amounts in the menu. a "custom amount" row is added.
--
-- to add a bank: add a line with x, y, z. the server checks you are standing at one.

Config.atmDailyLimit = 5000

Config.atmModels = { 'prop_atm_01', 'prop_atm_02', 'prop_atm_03', 'prop_fleeca_atm' }

Config.bankBlip = { sprite = 108, color = 2, scale = 0.55 }

Config.bankAmounts = { 100, 500, 1000, 5000, 10000 }

Config.banks = {
    { label = 'Fleeca Bank',      x = 149.05,   y = -1041.30, z = 29.37 },
    { label = 'Fleeca Bank',      x = 313.32,   y = -280.03,  z = 54.17 },
    { label = 'Fleeca Bank',      x = -351.94,  y = -50.72,   z = 49.04 },
    { label = 'Fleeca Bank',      x = -1212.68, y = -331.83,  z = 37.78 },
    { label = 'Fleeca Bank',      x = -2961.67, y = 482.31,   z = 15.70 },
    { label = 'Fleeca Bank',      x = 1175.64,  y = 2707.71,  z = 38.09 },
    { label = 'Pacific Standard', x = 247.65,   y = 223.87,   z = 106.29 },
    { label = 'Blaine County Savings', x = -111.98, y = 6470.56, z = 31.63 },
}
