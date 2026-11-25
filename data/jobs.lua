-- jobs: every job you can clock in to. the engine is modules/jobs.lua,
-- what a job actually does while you work is its own file in modules/jobs/.
--
-- what you set for each job:
--   label     the name you see
--   kind      'legit' or 'criminal'. criminal jobs will draw police attention
--             once the heat system exists (nothing uses this yet)
--   spot      { x, y, z } where you walk up and press E to clock in or out
--   blip      { sprite = , color = } the map icon (optional)
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
}
