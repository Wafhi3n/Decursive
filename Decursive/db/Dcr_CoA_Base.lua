-- Dcr_CoA_Base.lua
-- CoA / Ascension server module: custom class display names, setup tool, debug commands.
-- Only active when GetRealmName() contains "CoA" or "Ascension".
-- Merged from: Dcr_CoAClassDB.lua (display names), Dcr_CoASetup.lua, Dcr_CoADebug.lua

local addonName, T = ...;

if not T.IsCoAServer() then return; end

local D  = T.Dcr;
local DC = _G.DcrC;

if not D then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Decursive] Dcr_CoA_Base.lua: T.Dcr is nil, skipping|r");
    return;
end
if not DC then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Decursive] Dcr_CoA_Base.lua: DcrC is nil, skipping|r");
    return;
end

-- ============================================================
-- Inject CoA custom class display names into D.LC
-- (LOCALIZED_CLASS_NAMES_MALE does not include Ascension custom classes)
-- ============================================================
local CoAClassDisplayNames = {
    ["SUNCLERIC"]    = "Suncleric",
    ["BARBARIAN"]    = "Barbarian",
    ["WITCHDOCTOR"]  = "Witch Doctor",
    ["DEMONHUNTER"]  = "Demon Hunter",
    ["WITCHHUNTER"]  = "Witch Hunter",
    ["STORMBRINGER"] = "Stormbringer",
    ["FLESHWARDEN"]  = "Fleshwarden",
    ["GUARDIAN"]     = "Guardian",
    ["MONK"]         = "Monk",
    ["SONOFARUGAL"]  = "Son of a Rugal",
    ["RANGER"]       = "Ranger",
    ["PROPHET"]      = "Prophet",
    ["PYROMANCER"]   = "Pyromancer",
    ["CULTIST"]      = "Cultist",
    ["NECROMANCER"]  = "Necromancer",
    ["TINKER"]       = "Tinker",
    ["REAPER"]       = "Reaper",
    ["WILDWALKER"]   = "Wildwalker",
    ["STARCALLER"]   = "Starcaller",
    ["SPIRITMAGE"]   = "Spirit Mage",
    ["CHRONOMANCER"] = "Chronomancer",
};
for token, name in pairs(CoAClassDisplayNames) do
    if not D.LC[token] then
        D.LC[token] = name;
    end
end

-- ============================================================
-- CoA Setup state
-- ============================================================
local CoASetup = {
    spells = {},   -- { name, id, magic, disease, poison, curse, charmed, enemymagic, isBest, pet }
    output = "",   -- last generated Lua string
};
DC.CoASetup = CoASetup;

-- ============================================================
-- Spell type definitions
-- ============================================================
local TYPE_DEFS = {
    { key = "magic",      name = "Magic",      const = "DC.MAGIC"      },
    { key = "disease",    name = "Disease",    const = "DC.DISEASE"    },
    { key = "poison",     name = "Poison",     const = "DC.POISON"     },
    { key = "curse",      name = "Curse",      const = "DC.CURSE"      },
    { key = "charmed",    name = "Charm",      const = "DC.CHARMED"    },
    { key = "enemymagic", name = "EnemyMagic", const = "DC.ENEMYMAGIC" },
};

-- ============================================================
-- Scan spellbook → CoASetup.spells
-- ============================================================
function D:CoASetupScan()
    CoASetup.spells = {};
    for tabIndex = 1, GetNumSpellTabs() do
        local _, _, offset, numSpells = GetSpellTabInfo(tabIndex);
        for i = offset + 1, offset + numSpells do
            local skillType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL);
            if skillType ~= "FUTURESPELL" then
                local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL);
                if spellName and spellID then
                    table.insert(CoASetup.spells, {
                        name       = spellName,
                        id         = spellID,
                        magic      = false,
                        disease    = false,
                        poison     = false,
                        curse      = false,
                        charmed    = false,
                        enemymagic = false,
                        isBest     = 0,
                        pet        = false,
                    });
                end
            end
        end
    end
    D:CoASetupRebuildOptions();
end

-- ============================================================
-- Generate Lua output → CoASetup.output
-- ============================================================
function D:CoASetupGenerate()
    local _, classToken = UnitClass("player");
    local lines = {
        "-- Paste into DC.CoAClassDB[\"" .. tostring(classToken) .. "\"] in db/Dcr_CoA_Classes.lua",
        "[\"" .. tostring(classToken) .. "\"] = {",
    };
    for _, spell in ipairs(CoASetup.spells) do
        local types = {};
        for _, td in ipairs(TYPE_DEFS) do
            if spell[td.key] then
                table.insert(types, td.const);
            end
        end
        if #types > 0 then
            local key = "SPELL_" .. spell.name:upper():gsub("[^%w]", "_");
            table.insert(lines, "    [\"" .. key .. "\"] = {");
            table.insert(lines, "        ids    = { " .. tostring(spell.id) .. " },");
            table.insert(lines, "        Types  = { " .. table.concat(types, ", ") .. " },");
            table.insert(lines, "        IsBest = " .. tostring(spell.isBest or 0) .. ",");
            table.insert(lines, "        Pet    = " .. tostring(spell.pet or false) .. ",");
            table.insert(lines, "    },");
        end
    end
    table.insert(lines, "},");
    CoASetup.output = table.concat(lines, "\n");
end

-- ============================================================
-- Rebuild CoAClasses AceConfig args after scan
-- ============================================================
function D:CoASetupRebuildOptions()
    if not D.options then return; end
    local coaArgs = D.options.args.CoAClasses.args;

    -- Remove previous spell entries
    for k in pairs(coaArgs) do
        if k:sub(1, 6) == "spell_" then
            coaArgs[k] = nil;
        end
    end

    -- Add one inline group per spell
    for i, spell in ipairs(CoASetup.spells) do
        local idx = i;
        local spellArgs = {};

        -- Type toggles
        for t, td in ipairs(TYPE_DEFS) do
            local key = td.key;
            spellArgs[key] = {
                type  = "toggle",
                name  = td.name,
                order = t,
                get   = function()
                    return CoASetup.spells[idx] and CoASetup.spells[idx][key] or false;
                end,
                set   = function(info, v)
                    if CoASetup.spells[idx] then CoASetup.spells[idx][key] = v; end
                end,
            };
        end

        -- IsBest range slider (0 = none, 1 = best, 2 = best rank 2)
        spellArgs["isBest"] = {
            type  = "range",
            name  = "Best",
            min   = 0,
            max   = 2,
            step  = 1,
            order = 10,
            get   = function()
                return CoASetup.spells[idx] and CoASetup.spells[idx].isBest or 0;
            end,
            set   = function(info, v)
                if CoASetup.spells[idx] then CoASetup.spells[idx].isBest = v; end
            end,
        };

        -- Pet toggle
        spellArgs["pet"] = {
            type  = "toggle",
            name  = "Pet",
            order = 11,
            get   = function()
                return CoASetup.spells[idx] and CoASetup.spells[idx].pet or false;
            end,
            set   = function(info, v)
                if CoASetup.spells[idx] then CoASetup.spells[idx].pet = v; end
            end,
        };

        coaArgs["spell_" .. i] = {
            type   = "group",
            name   = spell.name .. "  [" .. tostring(spell.id) .. "]",
            order  = 100 + i,
            inline = true,
            args   = spellArgs,
        };
    end

    D:CoASetupRebuildDBOptions();
    LibStub("AceConfigRegistry-3.0"):NotifyChange("Decursive");
end

-- ============================================================
-- Apply or restore a single CoA spell in DC.SpellsToUse
-- ============================================================
local function ApplySpellToggle(classToken, key, disabled)
    if not DC.CoAClassDB or not DC.CoAClassDB[classToken] then return; end
    local data = DC.CoAClassDB[classToken][key];
    if not data then return; end
    local spellName = DC.DS and DC.DS[key];
    if not spellName or spellName == "_LOST SPELL_" then return; end
    if disabled then
        DC.SpellsToUse[spellName] = nil;
    else
        DC.SpellsToUse[spellName] = {
            Types      = data.Types,
            IsBest     = data.IsBest,
            Pet        = data.Pet,
            RangeSpell = data.RangeSpell,
        };
    end
end

-- ============================================================
-- Rebuild the "Active Dispel Spells" AceConfig toggles
-- Called at login and after scan to reflect DC.CoAClassDB state
-- ============================================================
function D:CoASetupRebuildDBOptions()
    if not D.options or not D.profile then return; end
    local coaArgs = D.options.args.CoAClasses.args;
    -- Remove previous dbspell entries
    for k in pairs(coaArgs) do
        if k:sub(1, 8) == "dbspell_" then coaArgs[k] = nil; end
    end
    if not C_Player or not C_Player:IsCustomClass() then return; end
    local _, classToken = UnitClass("player");
    local classSpells = DC.CoAClassDB and DC.CoAClassDB[classToken];
    if not classSpells or next(classSpells) == nil then return; end
    if not D.profile.CoASpellDisabled then D.profile.CoASpellDisabled = {}; end
    if not D.profile.CoASpellDisabled[classToken] then
        D.profile.CoASpellDisabled[classToken] = {};
    end
    local disabledMap = D.profile.CoASpellDisabled[classToken];
    local TYPE_MAP = {
        [DC.MAGIC]="Magic", [DC.ENEMYMAGIC]="EnemyMagic", [DC.CURSE]="Curse",
        [DC.POISON]="Poison", [DC.DISEASE]="Disease", [DC.CHARMED]="Charm",
    };
    local idx = 0;
    for key, data in pairs(classSpells) do
        idx = idx + 1;
        local k = key;
        local typeNames = {};
        for _, t in ipairs(data.Types or {}) do
            table.insert(typeNames, TYPE_MAP[t] or tostring(t));
        end
        local typeStr = #typeNames > 0 and table.concat(typeNames, ", ") or "?";
        local displayName = (DC.DS and DC.DS[k] and DC.DS[k] ~= "_LOST SPELL_" and DC.DS[k]) or k;
        coaArgs["dbspell_" .. k] = {
            type  = "toggle",
            name  = displayName .. "  |cff888888[" .. typeStr .. "]|r",
            desc  = "Enable or disable Decursive dispelling this spell.",
            order = 52 + idx,
            get   = function()
                return not (disabledMap[k]);
            end,
            set   = function(_, v)
                disabledMap[k] = not v;
                ApplySpellToggle(classToken, k, not v);
            end,
        };
    end
    LibStub("AceConfigRegistry-3.0"):NotifyChange("Decursive");
end

-- ============================================================
-- /dcrcoasetup slash command — scan + open options panel
-- ============================================================
function D:CoASetupOpen()
    D:CoASetupScan();
    LibStub("AceConfigDialog-3.0"):Open("Decursive");
end

-- ============================================================
-- /dcrcoainfo — print CoA class info and known DB entries
-- ============================================================
function D:CoAPrintClassInfo()
    local name, token = UnitClass("player");
    D:Print("|cff00ffffCoA Class Info:|r");
    D:Print("  UnitClass: token=|cffffd700" .. tostring(token) .. "|r  name=" .. tostring(name));
    if C_Player then
        D:Print("  C_Player.IsHero()=" .. tostring(C_Player:IsHero()));
        D:Print("  C_Player.IsDefaultClass()=" .. tostring(C_Player:IsDefaultClass()));
        D:Print("  C_Player.IsCustomClass()=" .. tostring(C_Player:IsCustomClass()));
    else
        D:Print("  |cffff0000C_Player API not available|r");
    end
    local classSpells = DC.CoAClassDB and DC.CoAClassDB[token];
    if classSpells then
        local count = 0;
        for _ in pairs(classSpells) do count = count + 1; end
        if count > 0 then
            D:Print("  DB entry: |cff00ff00found (" .. count .. " spells)|r");
            for key, data in pairs(classSpells) do
                local id = data.ids and data.ids[1];
                local spellName = id and GetSpellInfo(id);
                D:Print("    - " .. key .. " -> ID:" .. tostring(id) .. " -> " .. tostring(spellName));
            end
        else
            D:Print("  DB entry: |cffffff00empty (use /dcrcoasetup to populate)|r");
        end
    else
        D:Print("  DB entry: |cffff0000NOT FOUND for class " .. tostring(token) .. "|r");
    end
    -- Show DC.SpellsToUse count
    local suCount = 0;
    if DC.SpellsToUse then
        for _ in pairs(DC.SpellsToUse) do suCount = suCount + 1; end
    end
    D:Print("  DC.SpellsToUse entries: " .. suCount);
end

-- ============================================================
-- /dcrcoainfo scan — print all spellbook entries with IDs
-- ============================================================
function D:CoAScanSpellBook()
    D:Print("|cff00ffffCoA Spellbook Scan:|r");
    local found = 0;
    for tabIndex = 1, GetNumSpellTabs() do
        local tabName, _, offset, numSpells = GetSpellTabInfo(tabIndex);
        D:Print("  |cffffff00Tab " .. tabIndex .. ": " .. tostring(tabName) .. "|r");
        for i = offset + 1, offset + numSpells do
            local skillType, spellID = GetSpellBookItemInfo(i, BOOKTYPE_SPELL);
            if skillType ~= "FUTURESPELL" then
                local spellName = GetSpellBookItemName(i, BOOKTYPE_SPELL);
                if spellName then
                    D:Print("    [" .. i .. "] " .. spellName .. " (ID: " .. tostring(spellID or "?") .. ")");
                    found = found + 1;
                end
            end
        end
    end
    if found == 0 then D:Print("  No spells found."); end
    D:Print("  Total: " .. found .. " spells. Use /dcrcoasetup for interactive setup.");
end
