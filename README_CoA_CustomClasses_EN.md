# Decursive — CoA Custom Classes

Support for custom classes on the **Ascension / Vol'jin - CoA Beta** server (classless WotLK 3.3.5).

---

## Files Overview

| File | Role |
|---|---|
| `db/Dcr_CoAClassDB.lua` | Dispel spell database per custom class |
| `db/Dcr_CoASetup.lua` | Scan/configuration tool integrated in the options UI |
| `db/Dcr_CoADebug.lua` | Debug commands (`/dcrcoainfo`) |
| `Dcr_Raid.lua` | `ClassNumToUName` / `ClassNumToLName` tables (indices [22]–[42]) |
| `DCR_init.lua` | Injects CoA localized names into `D.LC` |
| `Dcr_opt.lua` | AceConfig "Custom Classes" group + `skipByClass` profile defaults |

---

## Supported Custom Classes

| Index | Token | Display Name |
|---|---|---|
| 22 | `SUNCLERIC` | Suncleric |
| 23 | `BARBARIAN` | Barbarian |
| 24 | `WITCHDOCTOR` | Witch Doctor |
| 25 | `DEMONHUNTER` | Demon Hunter |
| 26 | `WITCHHUNTER` | Witch Hunter |
| 27 | `STORMBRINGER` | Stormbringer |
| 28 | `FLESHWARDEN` | Fleshwarden |
| 29 | `GUARDIAN` | Guardian |
| 30 | `MONK` | Monk |
| 31 | `SONOFARUGAL` | Son of a Rugal |
| 32 | `RANGER` | Ranger |
| 33 | `PROPHET` | Prophet |
| 34 | `PYROMANCER` | Pyromancer |
| 35 | `CULTIST` | Cultist |
| 36 | `NECROMANCER` | Necromancer |
| 37 | `TINKER` | Tinker |
| 38 | `REAPER` | Reaper |
| 39 | `WILDWALKER` | Wildwalker |
| 40 | `STARCALLER` | Starcaller |
| 41 | `SPIRITMAGE` | Spirit Mage |
| 42 | `CHRONOMANCER` | Chronomancer |

> Custom classes appear in grey in the UI — they are not present in `RAID_CLASS_COLORS`, so Decursive falls back to a neutral colour.

---

## Configuring Spells for a Custom Class

### Via the in-game UI (recommended)

1. Log in with a character of the class you want to configure.
2. Open **Interface → AddOns → Decursive → Custom Classes**.
3. Click **Scan Spellbook** — your spell list will appear.
4. For each dispel spell, check the corresponding type(s):
   - **Magic** — removes a magical effect from an ally
   - **Disease** — removes a disease
   - **Poison** — removes a poison
   - **Curse** — removes a curse
   - **Charm** — removes a charm / mind control effect
   - **EnemyMagic** — removes a magical effect from an enemy (purge)
5. Set **Best** (0 / 1 / 2) — the spell's priority in the dispel rotation.
6. Check **Pet** if the spell is cast by a pet only.
7. Click **Generate Lua** — a code block appears in the panel.
8. Copy and paste that block into `db/Dcr_CoAClassDB.lua` at the indicated location.

### Slash commands

```
/dcrcoainfo          Print detected class and debug info
/dcrcoainfo scan     Scan the spellbook and list found spells
/dcrcoasetup         Open the Custom Classes panel and trigger a scan
```

---

## `Dcr_CoAClassDB.lua` Format

```lua
DC.CoAClassDB = {
    ["BARBARIAN"] = {
        ["SPELL_SLAM"] = {
            ids    = { 12345 },          -- spell ID
            Types  = { DC.MAGIC },       -- dispel types (see constants below)
            IsBest = 1,                  -- 0 = no, 1 = best, 2 = best rank 2
            Pet    = false,              -- pet spell?
        },
        ["SPELL_CLEAVE"] = {
            ids    = { 23456 },
            Types  = { DC.POISON, DC.CURSE },
            IsBest = 0,
            Pet    = false,
        },
    },
    ["WITCHDOCTOR"] = {
        -- ...
    },
    -- empty class = no known dispel spells
    ["TINKER"] = {},
};
```

### Available type constants

| Constant | Description |
|---|---|
| `DC.MAGIC` | Magical effect (ally) |
| `DC.DISEASE` | Disease |
| `DC.POISON` | Poison |
| `DC.CURSE` | Curse |
| `DC.CHARMED` | Charm / mind control |
| `DC.ENEMYMAGIC` | Enemy magic (purge) |

---

## Adding a New Custom Class

### 1. `Dcr_Raid.lua` — declare the class

Add an entry to both tables using the next available index:

```lua
DC.ClassNumToLName = {
    -- ...
    [42] = LC["CHRONOMANCER"],
    [43] = LC["MYCLASS"],       -- ← add here
}

DC.ClassNumToUName = {
    -- ...
    [42] = "CHRONOMANCER",
    [43] = "MYCLASS",           -- ← add here
}
```

### 2. `DCR_init.lua` — add the localized display name

In the `CoAClassDisplayNames` block:

```lua
local CoAClassDisplayNames = {
    -- ...
    ["CHRONOMANCER"] = "Chronomancer",
    ["MYCLASS"]      = "My Class",     -- ← add here
};
```

### 3. `Dcr_opt.lua` — initialise the `skipByClass` profile entry

In the `skipByClass` defaults table (~line 343):

```lua
["CHRONOMANCER"] = {},
["MYCLASS"]      = {},   -- ← add here
```

### 4. `db/Dcr_CoAClassDB.lua` — add the class to the DB

```lua
DC.CoAClassDB = {
    -- ...
    MYCLASS = {},   -- fill in after scanning in-game
};
```

---

## Technical Architecture

```
ADDON_LOADED
    └─ DCR_init.lua
        ├─ D.LC["SUNCLERIC"] = "Suncleric"  (CoA names injected)
        └─ DC.CoAClassDB loaded from db/Dcr_CoAClassDB.lua

Dcr_Raid.lua
    ├─ DC.ClassNumToUName[22..42] = CoA tokens
    └─ DC.ClassNumToLName[22..42] = display names

Dcr_opt.lua  (ExportOptions)
    ├─ AceConfig group "CoAClasses" registered
    └─ skipByClass defaults include all 21 CoA tokens

db/Dcr_CoASetup.lua  (developer tool)
    ├─ D:CoASetupScan()           → scan spellbook → CoASetup.spells
    ├─ D:CoASetupGenerate()       → build Lua string → CoASetup.output
    └─ D:CoASetupRebuildOptions() → inject inline groups into AceConfig
                                    + NotifyChange("Decursive")
```
