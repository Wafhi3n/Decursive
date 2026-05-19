# Decursive — CoA Custom Classes

Support des classes custom du serveur **Ascension / Vol'jin - CoA Beta** (classless WotLK 3.3.5).

---

## Fichiers concernés

| Fichier | Rôle |
|---|---|
| `db/Dcr_CoAClassDB.lua` | Base de données des sorts de dispel par classe custom |
| `db/Dcr_CoASetup.lua` | Outil de scan/configuration intégré dans l'UI options |
| `db/Dcr_CoADebug.lua` | Commandes de debug (`/dcrcoainfo`) |
| `Dcr_Raid.lua` | Tables `ClassNumToUName` / `ClassNumToLName` (indices [22]–[42]) |
| `DCR_init.lua` | Injection des noms localisés CoA dans `D.LC` |
| `Dcr_opt.lua` | Groupe AceConfig « Custom Classes » + profil `skipByClass` |

---

## Classes custom supportées

| Index | Token | Nom affiché |
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

> Les classes custom apparaissent en gris dans l'UI (couleur de fallback — elles ne sont pas dans `RAID_CLASS_COLORS`).

---

## Configurer les sorts d'une classe custom

### Via l'UI in-game (méthode recommandée)

1. Connecte-toi avec le personnage de la classe à configurer.
2. Ouvre **Interface → AddOns → Decursive → Custom Classes**.
3. Clique **Scan Spellbook** — la liste de tes sorts s'affiche.
4. Pour chaque sort de dispel, coche les types correspondants :
   - **Magic** — dépèche un effet magique
   - **Disease** — dépèche une maladie
   - **Poison** — dépèche un poison
   - **Curse** — dépèche une malédiction
   - **Charm** — dépèche un charme / contrôle mental
   - **EnemyMagic** — dépèche un effet magique sur un ennemi (purge)
5. Règle **Best** (0 / 1 / 2) : priorité du sort dans la rotation de dispel.
6. Coche **Pet** si le sort s'applique uniquement via familier.
7. Clique **Generate Lua** — un bloc de code apparaît dans le panneau.
8. Copie-colle ce bloc dans `db/Dcr_CoAClassDB.lua` à l'emplacement indiqué.

### Commandes slash utiles

```
/dcrcoainfo          Affiche la classe détectée + infos de debug
/dcrcoainfo scan     Scan le spellbook et affiche les sorts trouvés
/dcrcoasetup         Ouvre le panneau Custom Classes + lance un scan
```

---

## Format de `Dcr_CoAClassDB.lua`

```lua
DC.CoAClassDB = {
    ["BARBARIAN"] = {
        ["SPELL_SLAM"] = {
            ids    = { 12345 },          -- ID du sort
            Types  = { DC.MAGIC },       -- types de dispel (voir constantes)
            IsBest = 1,                  -- 0 = non, 1 = best, 2 = best rank 2
            Pet    = false,              -- sort de familier ?
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
    -- classe vide = pas de sort de dispel connu
    ["TINKER"] = {},
};
```

### Constantes de types disponibles

| Constante | Description |
|---|---|
| `DC.MAGIC` | Effet magique (allié) |
| `DC.DISEASE` | Maladie |
| `DC.POISON` | Poison |
| `DC.CURSE` | Malédiction |
| `DC.CHARMED` | Charme / contrôle mental |
| `DC.ENEMYMAGIC` | Magie ennemie (purge) |

---

## Ajouter une nouvelle classe custom

### 1. `Dcr_Raid.lua` — déclarer la classe

Ajouter une entrée dans les deux tables (prendre le prochain index libre) :

```lua
DC.ClassNumToLName = {
    -- ...
    [42] = LC["CHRONOMANCER"],
    [43] = LC["MACLASSE"],      -- ← ajouter ici
}

DC.ClassNumToUName = {
    -- ...
    [42] = "CHRONOMANCER",
    [43] = "MACLASSE",          -- ← ajouter ici
}
```

### 2. `DCR_init.lua` — ajouter le nom localisé

Dans le bloc `CoAClassDisplayNames` :

```lua
local CoAClassDisplayNames = {
    -- ...
    ["CHRONOMANCER"] = "Chronomancer",
    ["MACLASSE"]     = "Ma Classe",    -- ← ajouter ici
};
```

### 3. `Dcr_opt.lua` — initialiser le profil `skipByClass`

Dans la table `skipByClass` des defaults (ligne ~343) :

```lua
["CHRONOMANCER"] = {},
["MACLASSE"]     = {},   -- ← ajouter ici
```

### 4. `db/Dcr_CoAClassDB.lua` — ajouter la classe dans la DB

```lua
DC.CoAClassDB = {
    -- ...
    MACLASSE = {},   -- remplir après scan en jeu
};
```

---

## Architecture technique

```
ADDON_LOADED
    └─ DCR_init.lua
        ├─ D.LC["SUNCLERIC"] = "Suncleric"  (noms CoA injectés)
        └─ DC.CoAClassDB chargé depuis db/Dcr_CoAClassDB.lua

Dcr_Raid.lua
    ├─ DC.ClassNumToUName[22..42] = tokens CoA
    └─ DC.ClassNumToLName[22..42] = noms affichés

Dcr_opt.lua  (ExportOptions)
    ├─ AceConfig group "CoAClasses" enregistré
    └─ skipByClass defaults inclus les 21 tokens CoA

db/Dcr_CoASetup.lua  (outil développeur)
    ├─ D:CoASetupScan()          → scan spellbook → CoASetup.spells
    ├─ D:CoASetupGenerate()      → génère Lua → CoASetup.output
    └─ D:CoASetupRebuildOptions() → injecte groupes inline dans AceConfig
                                    + NotifyChange("Decursive")
```
