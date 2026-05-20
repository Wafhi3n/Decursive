local addonName, T = ...;
local DC = _G.DcrC;

-- Per CoA custom class dispell spell definitions
-- Format: [CLASS_TOKEN] = { [SPELL_KEY] = { ids={spellID,...}, Types={DC.TYPE,...}, IsBest=N, Pet=bool } }
-- Use /dcrcoasetup in-game to scan your spellbook and generate entries to paste here.
--
-- Types values: DC.MAGIC=1, DC.ENEMYMAGIC=2, DC.CURSE=4, DC.POISON=8, DC.DISEASE=16, DC.CHARMED=32
-- IsBest: 0=not best, 1=best, 2=only remove spell for that type
-- Pet: true if the spell also works on pets
--
-- Example entry (uncomment and fill with IDs from /dcrcoasetup scan):
-- SUNCLERIC = {
--     ["SPELL_SANCTIFY"] = {
--         ids    = { 524968 },
--         Types  = { DC.MAGIC, DC.DISEASE, DC.POISON, DC.CURSE },
--         IsBest = 2,
--         Pet    = false,
--     },
-- },

DC.CoAClassDB = {
    -- ── SUNCLERIC ──────────────────────────────────────────────────────────
    SUNCLERIC = {
        ["SPELL_SANCTIFY"] = {           -- dispel 1 magic, poison, disease
            ids    = { 524968 },
            Types  = { DC.MAGIC, DC.POISON, DC.DISEASE },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── STARCALLER ─────────────────────────────────────────────────────────
    STARCALLER = {
        ["SPELL_PRAYER_OF_ELUNE"] = {    -- AoE heal + dispel 1 harmful magic (non-targeted AoE)
            ids       = { 801987, 502348, 502349, 502350, 502351, 575334 },  -- 801987=rank1 (must be first)
            Types     = { DC.MAGIC },
            IsBest    = 2,
            Pet       = false,
            RangeSpell = "Moonwell Splash", -- targeted ally spell used for range check
        },
        ["SPELL_ELUNES_PURIFICATION"] = { -- remove 1 poison and disease from ally
            ids    = { 520869 },
            Types  = { DC.POISON, DC.DISEASE },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── MONK ───────────────────────────────────────────────────────────────
    MONK = {
        ["SPELL_REBUKE"] = {             -- dispel 2 magic, poison, disease
            ids    = { 525051 },
            Types  = { DC.MAGIC, DC.POISON, DC.DISEASE },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── CULTIST ────────────────────────────────────────────────────────────
    CULTIST = {
        ["SPELL_DEVOUR_MAGIC"] = {       -- devour 1 harmful magic, self-heal
            ids    = { 520151 },
            Types  = { DC.MAGIC },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── SPIRITMAGE ─────────────────────────────────────────────────────────
    SPIRITMAGE = {
        ["SPELL_RESONANCE_RUNE"] = {     -- AoE ground rune: dispel 3 magic allies + purge 3 enemy
            -- IsSpellInRange returns nil for ground-AoE → nil→1 fallback handles range
            ids    = { 803679 },
            Types  = { DC.MAGIC, DC.ENEMYMAGIC },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── CHRONOMANCER ───────────────────────────────────────────────────────
    CHRONOMANCER = {
        ["SPELL_ROLL_BACK"] = {          -- dispel last harmful effect on ally
            ids    = { 804490 },
            Types  = { DC.MAGIC },
            IsBest = 2,
            Pet    = false,
        },
        ["SPELL_BABIFY"] = {             -- polymorph-like enemy CC
            ids    = { 804461 },
            Types  = { DC.CHARMED },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── WITCHDOCTOR ────────────────────────────────────────────────────────
    WITCHDOCTOR = {
        ["SPELL_ALLCURE_ELIXIR"] = {     -- remove ALL poison, disease, curse + immunity 3s
            ids    = { 804049 },
            Types  = { DC.POISON, DC.DISEASE, DC.CURSE },
            IsBest = 2,
            Pet    = false,
        },
        ["SPELL_HEXBREAK"] = {           -- dispel 1 curse (weaker than Allcure)
            ids    = { 806240 },
            Types  = { DC.CURSE },
            IsBest = 0,
            Pet    = false,
        },
    },
    -- ── TINKER ─────────────────────────────────────────────────────────────
    TINKER = {
        ["SPELL_MED_PACK"] = {           -- cleanse all bleed, poison, disease
            ids    = { 502533, 502534, 502535, 502536 },
            Types  = { DC.POISON, DC.DISEASE },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── WILDWALKER ─────────────────────────────────────────────────────────
    WILDWALKER = {
        ["SPELL_BOON_OF_THE_LION"] = {   -- dispel 1 fear/charm/sleep
            ids    = { 504856 },
            Types  = { DC.CHARMED },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── PROPHET ────────────────────────────────────────────────────────────
    PROPHET = {
        ["SPELL_ANTIVENOM"] = {          -- cure 1 poison, repeating for 12 sec
            ids    = { 800905 },
            Types  = { DC.POISON },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── REAPER ─────────────────────────────────────────────────────────────
    REAPER = {
        ["SPELL_SOUL_SHEAR"] = {         -- purge 2 beneficial magic from enemy
            ids    = { 520862 },
            Types  = { DC.ENEMYMAGIC },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── WITCHHUNTER ────────────────────────────────────────────────────────
    WITCHHUNTER = {
        ["SPELL_PURGE_EVIL"] = {         -- remove all enrage effects from enemy
            ids    = { 572306 },
            Types  = { DC.ENEMYMAGIC },
            IsBest = 2,
            Pet    = false,
        },
    },
    -- ── Classes with no dispel spells ──────────────────────────────────────
    BARBARIAN    = {},
    DEMONHUNTER  = {},
    FLESHWARDEN  = {},
    GUARDIAN     = {},
    NECROMANCER  = {},
    PYROMANCER   = {},
    RANGER       = {},
    SONOFARUGAL  = {
        ["SPELL_HYPOVOLEMIC_SHOCK"] = {  -- AP debuff + remove 1 enrage from enemy
            ids    = { 572305, 572409, 572410, 572411, 572412 },
            Types  = { DC.ENEMYMAGIC },
            IsBest = 2,
            Pet    = false,
        },
    },
    STORMBRINGER = {
        ["SPELL_STORMBREAKER"] = {       -- purge 1 beneficial magic from enemy
            ids    = { 705669 },
            Types  = { DC.ENEMYMAGIC },
            IsBest = 2,
            Pet    = false,
        },
        ["SPELL_CALM_THE_STORM"] = {     -- remove 1 enrage from enemy (requires 10 Static)
            ids    = { 572303 },
            Types  = { DC.ENEMYMAGIC },
            IsBest = 1,
            Pet    = false,
        },
    },
    HERO         = {},  -- Hero classless uses heroSpells directly
};
