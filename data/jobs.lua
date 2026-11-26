-- jobs: every job you can clock in to. the engine is modules/jobs.lua,
-- what a job actually does while you work is its own file in modules/jobs/.
--
-- what you set for each job:
--   label     the name you see
--   kind      'legit' or 'criminal'. criminal jobs will draw police attention
--             once the heat system exists (nothing uses this yet)
--   spot      { x, y, z } where you walk up and press E to clock in or out
--   blip      { sprite = , color = } the map icon (optional). criminal jobs never get one:
--             their spot stays off the map, and the girl and customer blips of a job
--             only exist on your own screen while you are working
--   pay       { min = , max = } what one payout is before your rank bonus
--   every     real milliseconds of ACTIVE work between payouts (60000 = 1 minute)
--   repPerPay reputation you earn with each payout (rank comes from reputation)
--   idle      (optional) milliseconds you can stay inactive before you are
--             clocked out. without it, Config.jobIdleLimit is used.
--   ranks     (optional) your own rank list for this job, same shape as JobRanks
--
-- "active" is decided by the job's own file (for the courier: you are driving
-- and moving). payouts only count up while the job is active.

-- ranks every job uses unless it has its own.
-- rep = reputation needed, bonus = multiplier on the pay
JobRanks = {
    { name = 'Rookie',  rep = 0,     bonus = 1.0 },
    { name = 'Regular', rep = 500,   bonus = 1.15 },
    { name = 'Hustler', rep = 1500,  bonus = 1.3 },
    { name = 'Boss',    rep = 4000,  bonus = 1.5 },
    { name = 'Kingpin', rep = 10000, bonus = 1.8 },
}

Jobs = {
    -- the first job, mostly to prove the system works. drive around and get paid.
    courier = {
        label = 'Courier', kind = 'legit',
        spot = { x = 195.17, y = -933.77, z = 29.7 },   -- Legion Square
        blip = { sprite = 477, color = 5 },
        pay = { min = 30, max = 50 }, every = 60000, repPerPay = 10,
    },

    -- the pimping job. pick up your girls, drive them to customers, collect, get paid.
    -- it has no "every": it is paid per customer instead of by the timer.
    -- the spot is not set yet: stand where you want it and use /setjobspot pimp
    pimp = {
        label = 'Pimping', kind = 'criminal',
        pay = { min = 100, max = 150 }, repPerPay = 10,
        streakBonus = 20, streakCap = 200,       -- extra per customer in a row (lost when you fail)
        problemChance = 8,                       -- percent of customers that refuse to pay
        rivalChance = 5,                         -- percent that turn into a rival gang
        repProblem = 50, repRival = 100, repFail = 30,   -- rep for winning, rep lost for failing
        -- rival gang difficulty: how many, how well they shoot (0 to 100), and how close
        -- you get before they come for you (meters)
        rivalCount = 2, rivalAccuracy = { min = 25, max = 40 }, rivalAttackDistance = 60.0,
        spawnRadius = 250.0,                     -- girls and customers appear this far from you at most (meters)
        -- the number of girls working for you comes from your rank
        ranks = {
            { name = 'Rookie',  rep = 0,     bonus = 1.0,  girls = 2 },
            { name = 'Regular', rep = 500,   bonus = 1.15, girls = 3 },
            { name = 'Hustler', rep = 1500,  bonus = 1.3,  girls = 4 },
            { name = 'Boss',    rep = 4000,  bonus = 1.5,  girls = 5 },
            { name = 'Kingpin', rep = 10000, bonus = 1.8,  girls = 5 },
        },
        -- ped models. swap any of these for other models to change the look of the job.
        girlModels     = { 's_f_y_hooker_01', 's_f_y_hooker_02', 's_f_y_hooker_03' },
        customerModels = { 'a_m_y_business_01', 'a_m_m_business_01', 'a_m_y_hipster_01', 'a_m_m_eastsa_01',
                           'a_m_y_skater_01', 'a_m_m_afriamer_01', 'a_m_m_bevhills_01', 'a_m_m_salton_01' },
        rivalModels    = { 'g_m_y_ballasout_01', 'g_m_y_ballaeast_01', 'g_m_y_ballaorig_01' },
        rivalWeapons   = { 'WEAPON_PISTOL', 'WEAPON_KNIFE', 'WEAPON_BAT' },
        names = { 'Roxy', 'Dixie', 'Vera', 'Mimi', 'Pearl', 'Tina', 'Gigi', 'Lola', 'Cleo', 'Dina', 'Nova', 'Sasha' },
        -- what the girls say. one line is picked at random from each list.
        text = {
            pickup   = { "I'm out here. Come get me.", 'Ready when you are, boss.', "Waiting on the corner.", "Hurry up, it's cold out here." },
            customer = { 'Got a guy lined up. Take me to him.', "There's a man waiting, blue dot on your map.", 'Customer found. Drive.' },
            away     = { "Go for a drive. I'll text you.", "Don't go far.", 'This will take a while.', "Give me a few minutes." },
            ready    = { "I'm done. Come get me.", 'All finished, pick me up.', 'Done here. Where are you?' },
            problem  = { "He won't pay! Get over here!", 'This guy is trying to skip out on me!', "He's running with my money, stop him!" },
            rival    = { "Somebody is trying to move in on us!", 'Rival crew just showed up, hurry!', "We've got company, and it isn't friendly." },
            success  = { "That's how it's done.", 'Nice work. You earned extra.', 'Perfect. Nobody messes with us.' },
            fail     = { "You let him get away.", "What do I pay you for?", "That's coming out of your cut." },
            lost     = { "One of your girls didn't make it. A new one will be along.", 'You lost a girl. Another is on her way.' },
        },
    },
}
