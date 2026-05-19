local addonName, T = ...;
local D  = T and T.Dcr;
local DC = _G.DcrC;

if not D then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Decursive] Dcr_CoASetup.lua: T.Dcr is nil, skipping|r");
    return;
end
if not DC then
    DEFAULT_CHAT_FRAME:AddMessage("|cffff0000[Decursive] Dcr_CoASetup.lua: DcrC is nil, skipping|r");
    return;
end

-- CoA Setup state
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
-- Scan spellbook â†’ CoASetup.spells
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
-- Generate Lua output â†’ CoASetup.output
-- ============================================================
function D:CoASetupGenerate()
    local _, classToken = UnitClass("player");
    local lines = {
        "-- Paste into DC.CoAClassDB[\"" .. tostring(classToken) .. "\"] in db/Dcr_CoAClassDB.lua",
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

    LibStub("AceConfigRegistry-3.0"):NotifyChange("Decursive");
end

-- ============================================================
-- /dcrcoasetup slash command — scan + open options panel
-- ============================================================
function D:CoASetupOpen()
    D:CoASetupScan();
    LibStub("AceConfigDialog-3.0"):Open("Decursive");
end
