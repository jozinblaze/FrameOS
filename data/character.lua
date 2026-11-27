-- character: everything the creator offers, in one place. both the screen and the server read this,
-- the server uses it to check every number it is sent (see server/character.lua).
--
-- a saved character (d.character on the server) looks like this:
--   { name = { first = 'Jason', last = 'Blazze' },
--     sex = 'm' or 'f',
--     look = { mother, father, shapeMix, skinMix, features = { 20 numbers -1 to 1 },
--              overlays = { { id, style, opacity, color } ... }   (an overlay that is off is not in the list),
--              hair = { style, color, highlight }, eyes },
--     outfit = { parts = { { id, drawable, texture } ... }, props = { { id, drawable, texture } ... } } }
-- the barbers and clothing stores later change look and outfit and send them the same way.

Config.character = {
    models = { m = 'mp_m_freemode_01', f = 'mp_f_freemode_01' },

    -- the face "parents". the game numbers its mother faces 21 to 41 and its father faces 0 to 20.
    mothers = { first = 21, last = 41 },
    fathers = { first = 0, last = 20 },

    -- the 20 face sliders, in the order the game numbers them (0 to 19)
    features = {
        'Nose width', 'Nose peak height', 'Nose peak length', 'Nose bone height', 'Nose peak lowering',
        'Nose bone twist', 'Eyebrow height', 'Eyebrow depth', 'Cheekbone height', 'Cheekbone width',
        'Cheek width', 'Eye opening', 'Lip thickness', 'Jaw width', 'Jaw length',
        'Chin height', 'Chin length', 'Chin width', 'Chin hole size', 'Neck thickness',
    },

    -- skin and face overlays. id is the game's overlay number, max is the highest style number.
    -- color: 1 = uses the hair color list, 2 = uses the makeup color list, nil = no color.
    overlays = {
        { id = 0,  name = 'Blemishes',   max = 23 },
        { id = 1,  name = 'Facial hair', max = 28, color = 1 },
        { id = 2,  name = 'Eyebrows',    max = 33, color = 1 },
        { id = 3,  name = 'Ageing',      max = 14 },
        { id = 4,  name = 'Makeup',      max = 74, color = 2 },
        { id = 5,  name = 'Blush',       max = 6,  color = 2 },
        { id = 6,  name = 'Complexion',  max = 11 },
        { id = 7,  name = 'Sun damage',  max = 10 },
        { id = 8,  name = 'Lipstick',    max = 9,  color = 2 },
        { id = 9,  name = 'Freckles',    max = 17 },
        { id = 10, name = 'Chest hair',  max = 16, color = 1 },
    },

    hairColors = 63,     -- hair colors run 0 to this
    eyeColors = 31,      -- eye colors run 0 to this
    hairMax = 255,       -- the server only checks hair is a sane number, the screen knows the real limit

    -- clothing slots and props that are part of the outfit (head 0 and hair 2 are part of the look)
    outfitParts = { 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 },
    outfitProps = { 0, 1, 2, 6, 7 },

    nameMin = 2,
    nameMax = 16,

    -- the starter outfits you can pick in the creator. "Default" is the game's own starting outfit
    -- and always works. the others are slot numbers, written { slot, number, texture }.
    -- these numbers are a first guess: if one looks wrong in game, find better numbers with /clothinfo
    -- and /cloth and put them here. the real clothing stores come later and use the same slots.
    outfits = {
        { name = 'Default' },
        { name = 'Basic',        parts = { { 11, 0, 0 }, { 8, 0, 0 }, { 3, 0, 0 }, { 4, 0, 0 }, { 6, 0, 0 } } },
        { name = 'Basic, darker', parts = { { 11, 0, 1 }, { 8, 0, 0 }, { 3, 0, 0 }, { 4, 0, 1 }, { 6, 0, 1 } } },
        { name = 'Basic, bright', parts = { { 11, 0, 2 }, { 8, 0, 0 }, { 3, 0, 0 }, { 4, 0, 2 }, { 6, 0, 0 } } },
    },
}
