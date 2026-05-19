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
-- Paste the block below into DC.CoAClassDB['SUNCLERIC'] in db/Dcr_CoAClassDB.lua
SUNCLERIC = {
    ["SPELL_SANCTIFY"] = {
        ids    = { 524968 },
        Types  = { DC.MAGIC, DC.POISON, DC.DISEASE },
        IsBest = 2,
        Pet    = false,
    },
},    BARBARIAN    = {},
    WITCHDOCTOR  = {},
    DEMONHUNTER  = {},
    WITCHHUNTER  = {},
    STORMBRINGER = {},
    FLESHWARDEN  = {},
    GUARDIAN     = {},
    MONK         = {},
    SONOFARUGAL  = {},
    RANGER       = {},
    PROPHET      = {},
    PYROMANCER   = {},
    CULTIST      = {},
    NECROMANCER  = {},
    TINKER       = {},
    REAPER       = {},
    WILDWALKER   = {},
    STARCALLER   = {},
    SPIRITMAGE   = {},
    CHRONOMANCER = {},
    HERO         = {},  -- Hero classless uses heroSpells directly
};
