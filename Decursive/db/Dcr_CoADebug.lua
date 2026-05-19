local addonName, T = ...;
local D  = T.Dcr;
local DC = _G.DcrC;
local DS = DC.DS;

-- /dcrcoainfo — print CoA class info and known DB entries
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

-- /dcrcoainfo scan — print all spellbook entries with IDs
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
