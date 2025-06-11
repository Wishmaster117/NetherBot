--------------------------------------------------------------------
-- File: data/data.lua  – utilise AceLocale + fonction i18n()
--------------------------------------------------------------------
local ADDON_NAME, NS = ...
local DATA = {}

------------------------------------------------------------------
-- CONSTANTES ID --------------------------------------------------
------------------------------------------------------------------
local R = {
  HUMAN      = 1,
  ORC        = 2,
  DWARF      = 3,
  NIGHTELF   = 4,
  UNDEAD     = 5,
  TAUREN     = 6,
  GNOME      = 7,
  TROLL      = 8,
  BLOODELF   = 10,
  DRAENEI    = 11,
}

local G = { MALE = 0, FEMALE = 1 }

------------------------------------------------------------------
-- FONCTION i18n : fournie par l’addon principal ------------------
------------------------------------------------------------------
-- Assure qu’elle existe même si data.lua est chargé avant le core.
local AceLocale = LibStub("AceLocale-3.0")
local Lx = AceLocale:GetLocale("NetherBot", true)  -- silent=true (pas d’erreur si locale pas encore définie)
local function i18n(key)
  if Lx and Lx[key] then return Lx[key] end
  return key  -- fallback propre
end

------------------------------------------------------------------
-- LISTES EXPOSÉES (affichage via i18n) ---------------------------
------------------------------------------------------------------
DATA.Classes = {
  [1]  = i18n("CLASS_WARRIOR"),       [2]  = i18n("CLASS_PALADIN"),
  [3]  = i18n("CLASS_HUNTER"),        [4]  = i18n("CLASS_ROGUE"),
  [5]  = i18n("CLASS_PRIEST"),        [6]  = i18n("CLASS_DEATHKNIGHT"),
  [7]  = i18n("CLASS_SHAMAN"),        [8]  = i18n("CLASS_MAGE"),
  [9]  = i18n("CLASS_WARLOCK"),       [11] = i18n("CLASS_DRUID"),
  [12] = i18n("CLASS_BLADEMASTER"),   [13] = i18n("CLASS_SPHYNX"),
  [14] = i18n("CLASS_ARCHMAGE"),      [15] = i18n("CLASS_DREADLORD"),
  [16] = i18n("CLASS_SPELLBREAKER"),  [17] = i18n("CLASS_DARKRANGER"),
  [18] = i18n("CLASS_NECROMANCER"),   [19] = i18n("CLASS_SEAWITCH"),
}

DATA.Races = {
  [R.HUMAN]    = i18n("RACE_HUMAN"),
  [R.ORC]      = i18n("RACE_ORC"),
  [R.DWARF]    = i18n("RACE_DWARF"),
  [R.NIGHTELF] = i18n("RACE_NIGHTELF"),
  [R.UNDEAD]   = i18n("RACE_UNDEAD"),
  [R.TAUREN]   = i18n("RACE_TAUREN"),
  [R.GNOME]    = i18n("RACE_GNOME"),
  [R.TROLL]    = i18n("RACE_TROLL"),
  [R.BLOODELF] = i18n("RACE_BLOODELF"),
  [R.DRAENEI]  = i18n("RACE_DRAENEI"),
}

DATA.Genders = {
  [G.MALE]   = i18n("GENDER_MALE"),
  [G.FEMALE] = i18n("GENDER_FEMALE"),
}

DATA.Soundset = {
  [0] = i18n("SOUNDSET_DEFAULT"),   -- ex. « Voix standard »
  [1] = i18n("SOUNDSET_VARIANT1"),  -- ex. « Variante 1 »
  [2] = i18n("SOUNDSET_VARIANT2"),  -- ex. « Variante 2 »
}

------------------------------------------------------------------
-- OUTIL : liste séquentielle 0‑max -------------------------------
------------------------------------------------------------------
local function buildRange(max)
  local t = {}
  for i = 0, max do
    t[i + 1] = tostring(i)   -- clé 1..N  /  texte "0".."N"
  end
  return t
end

------------------------------------------------------------------
-- RANGES VISUELS PAR RACE & GENRE --------------------------------
------------------------------------------------------------------
DATA.Visuals = {
  [R.HUMAN]   = { [G.MALE]={9,11,16,9,8}, [G.FEMALE]={9,14,23,9,6} },
  [R.DWARF]   = { [G.MALE]={8,9,15,9,10}, [G.FEMALE]={8,9,18,9,5} },
  [R.NIGHTELF]= { [G.MALE]={8,8,11,7,5},  [G.FEMALE]={8,8,11,7,9} },
  [R.GNOME]   = { [G.MALE]={4,6,11,8,7},  [G.FEMALE]={4,6,11,8,6} },
  [R.DRAENEI] = { [G.MALE]={13,9,13,6,7}, [G.FEMALE]={13,9,15,6,6} },
  [R.ORC]     = { [G.MALE]={8,8,11,7,10}, [G.FEMALE]={8,8,12,7,6} },
  [R.UNDEAD]  = { [G.MALE]={5,9,14,9,16}, [G.FEMALE]={5,9,14,9,7} },
  [R.TAUREN]  = { [G.MALE]={18,4,12,2,6}, [G.FEMALE]={10,3,11,2,4} },
  [R.TROLL]   = { [G.MALE]={5,4,9,9,10},  [G.FEMALE]={5,5,9,9,5} },
  [R.BLOODELF]= { [G.MALE]={9,9,15,9,9},  [G.FEMALE]={9,9,18,9,10}},
}

------------------------------------------------------------------
-- API UTILITAIRE -------------------------------------------------
------------------------------------------------------------------
function DATA:GetVisualRange(race, gender, key)
  local v = self.Visuals[race] and self.Visuals[race][gender]
  if not v then return 0 end
  if     key=="skin"      then return v[1]
  elseif key=="face"      then return v[2]
  elseif key=="hair"      then return v[3]
  elseif key=="haircolor" then return v[4]
  elseif key=="features"  then return v[5]
  end
  return 0
end

function DATA:BuildRangeList(race, gender, key)
  return buildRange(self:GetVisualRange(race, gender, key))
end

------------------------------------------------------------------
-- TABLEAU CORRESPONDANCES POUR PREVIEW --------------------------
------------------------------------------------------------------
DATA.DisplayID = {
  [1]  = { [0] = 49,   [1] = 50  },   -- Humain
  [2]  = { [0] = 1478, [1] = 1479 },  -- Orc
  [3]  = { [0] = 51,   [1] = 52  },   -- Nain
  [4]  = { [0] = 55,   [1] = 56  },   -- Elfe de la nuit
  [5]  = { [0] = 57,   [1] = 58  },   -- Mort-vivant
  [6]  = { [0] = 59,   [1] = 60  },   -- Tauren
  [7]  = { [0] = 1563, [1] = 1564},   -- Gnome
  [8]  = { [0] = 1472, [1] = 1473},   -- Troll
  [10] = { [0] = 15476,[1] = 15475},  -- Elfe de sang
  [11] = { [0] = 16125,[1] = 16126},  -- Draeneï
}

DATA.ModelPath = {
  [1]  = { [0]="Character\\Human\\Male\\HumanMale.m2",     [1]="Character\\Human\\Female\\HumanFemale.m2" },
  [2]  = { [0]="Character\\Orc\\Male\\OrcMale.m2",         [1]="Character\\Orc\\Female\\OrcFemale.m2" },
  [3]  = { [0]="Character\\Dwarf\\Male\\DwarfMale.m2",     [1]="Character\\Dwarf\\Female\\DwarfFemale.m2" },
  [4]  = { [0]="Character\\NightElf\\Male\\NightElfMale.m2",[1]="Character\\NightElf\\Female\\NightElfFemale.m2" },
  [5]  = { [0]="Character\\Scourge\\Male\\ScourgeMale.m2", [1]="Character\\Scourge\\Female\\ScourgeFemale.m2" },
  [6]  = { [0]="Character\\Tauren\\Male\\TaurenMale.m2",   [1]="Character\\Tauren\\Female\\TaurenFemale.m2" },
  [7]  = { [0]="Character\\Gnome\\Male\\GnomeMale.m2",     [1]="Character\\Gnome\\Female\\GnomeFemale.m2" },
  [8]  = { [0]="Character\\Troll\\Male\\TrollMale.m2",     [1]="Character\\Troll\\Female\\TrollFemale.m2" },
  [10] = { [0]="Character\\BloodElf\\Male\\BloodElfMale.m2",[1]="Character\\BloodElf\\Female\\BloodElfFemale.m2" },
  [11] = { [0]="Character\\Draenei\\Male\\DraeneiMale.m2", [1]="Character\\Draenei\\Female\\DraeneiFemale.m2" },
}

------------------------------------------------------------------
NS.NB_DATA = DATA
_G.NB_DATA = DATA
--------------------------------------------------------------------
