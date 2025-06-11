--------------------------------------------------------------------
--  NetherBot – Ace3 (3.3.5a)  •  locale-safe + scale-fix
--------------------------------------------------------------------
local AceAddon   = LibStub("AceAddon-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceEvent   = LibStub("AceEvent-3.0")
local AceGUI     = LibStub("AceGUI-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local GUI = LibStub("AceGUI-3.0")


-- 1) CRÉATION DE L’ADDON (doit venir en tout début)
local NetherBot = AceAddon:NewAddon("NetherBot", "AceConsole-3.0", "AceEvent-3.0")

-- 2) Chargement des locales & utilitaires
local L = AceLocale:GetLocale("NetherBot")
local function i18n(key)
  return (L and L[key]) or key
end

-- 2) Plus bas, une fois l’addon créé, récupérez les libs :
local LDB     = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0",       true)

--------------------------------------------------------------------
--  Patch Module création de Bots
--------------------------------------------------------------------

--------------------------------------------------------------------
-- 1. Table NB_DATA
--------------------------------------------------------------------
local NB_DATA = _G.NB_DATA or error("[NetherBot] NB_DATA manquant (data/data.lua non chargé ?)")

local function buildList(src)
  local t = {}
  for k, v in pairs(src) do t[k] = v end
  return t
end

--------------------------------------------------------------------
-- 2. getLabel : déclaré AVANT la frame
--------------------------------------------------------------------
local function getLabel(cat, race, idx)
  local tbl = NB_DATA.Labels[cat] and NB_DATA.Labels[cat][race]
  if tbl and tbl[idx] then return tbl[idx] end
  return "#" .. tostring(idx)
end

-- Création / MAJ dynamique des listes visuelles ------------------
local function updateVisualDropdowns(race, gender, ddSkin, ddFace, ddHair, ddHairCol, ddFeat)
  if not (race and gender) then return end
  ddSkin:SetList(NB_DATA:BuildRangeList(race, gender, "skin"))
  ddFace:SetList(NB_DATA:BuildRangeList(race, gender, "face"))
  ddHair:SetList(NB_DATA:BuildRangeList(race, gender, "hair"))
  ddHairCol:SetList(NB_DATA:BuildRangeList(race, gender, "haircolor"))
  ddFeat:SetList(NB_DATA:BuildRangeList(race, gender, "features"))
end


--------------------------------------------------------------------
-- 3. Fenêtre
--------------------------------------------------------------------
function NetherBot:ShowCreateBotFrame()
  if self.createBotFrame and self.createBotFrame:IsShown() then return end
  local AceGUI = LibStub("AceGUI-3.0")
  local f = AceGUI:Create("Frame")
  f:SetTitle(i18n("BOT_CREATE_TITLE"))
  f:SetLayout("Flow")
  f:SetWidth(380)
  f:SetHeight(480)
  self.createBotFrame = f

----------------------------------------------------------------
-- Tooltips
----------------------------------------------------------------
local function addTooltip(widget, text)
  -- cible réelle : editbox si présent, sinon frame du widget
  local target = widget.editbox or widget.frame
  target:EnableMouse(true)                     -- indispensable pour EditBox
  target:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:AddLine(text, 1, 1, 1, true)
      GameTooltip:Show()
  end)
  target:SetScript("OnLeave", GameTooltip_Hide)
end

  ----------------------------------------------------------------
  -- Widgets principaux
  ----------------------------------------------------------------
  local nameBox = AceGUI:Create("EditBox"); nameBox:SetLabel(i18n("BOT_NAME")); nameBox:SetFullWidth(true); addTooltip(nameBox, i18n("BOT_NAME_TOOLTIP")); nameBox.button:Hide(); f:AddChild(nameBox)

  local ddClass = AceGUI:Create("Dropdown"); ddClass:SetLabel(i18n("BOT_CLASS")); ddClass:SetList(buildList(NB_DATA.Classes)); ddClass:SetWidth(200); f:AddChild(ddClass)
  local ddRace  = AceGUI:Create("Dropdown"); ddRace:SetLabel(i18n("BOT_RACE")); ddRace:SetList(buildList(NB_DATA.Races));  ddRace:SetWidth(200); f:AddChild(ddRace)
  local ddGender= AceGUI:Create("Dropdown"); ddGender:SetLabel(i18n("BOT_GENDER"));       ddGender:SetList(buildList(NB_DATA.Genders)); ddGender:SetWidth(100); f:AddChild(ddGender)

  local ddSkin  = AceGUI:Create("Dropdown"); ddSkin:SetLabel(i18n("BOT_SKIN"));          ddSkin:SetWidth(90); f:AddChild(ddSkin)
  local ddFace  = AceGUI:Create("Dropdown"); ddFace:SetLabel(i18n("BOT_FACE"));        ddFace:SetWidth(90); f:AddChild(ddFace)
  local ddHair  = AceGUI:Create("Dropdown"); ddHair:SetLabel(i18n("BOT_HAIRSTYLE"));       ddHair:SetWidth(110); f:AddChild(ddHair)
  local ddHairC = AceGUI:Create("Dropdown"); ddHairC:SetLabel(i18n("BOT_HAIRCOLOR"));      ddHairC:SetWidth(110); f:AddChild(ddHairC)
  local ddFeat = AceGUI:Create("Dropdown"); ddFeat:SetLabel(i18n("BOT_FEATURES"));       ddFeat:SetWidth(90); addTooltip(ddFeat, i18n("BOT_FEATURES_TOOLTIP")); f:AddChild(ddFeat)
  local ddSS    = AceGUI:Create("Dropdown"); ddSS:SetLabel(i18n("BOT_SOUNDSET"));       ddSS:SetList(buildList(NB_DATA.Soundset)); ddSS:SetWidth(90); f:AddChild(ddSS)

----------------------------------------------------------------
-- Résumé dynamique
----------------------------------------------------------------
local summary = AceGUI:Create("Label")
summary:SetFullWidth(true)
summary:SetFontObject(GameFontHighlight)   -- objet, plus d’erreur
summary:SetText(" ")                      -- une ligne vide pour réserver la place
f:AddChild(summary)

  ----------------------------------------------------------------
  -- Ranges
  ----------------------------------------------------------------
local function fillRanges()
  local r,g = ddRace:GetValue(), ddGender:GetValue()
  if not (r and g) then return end
  ddSkin:SetList(NB_DATA:BuildRangeList(r,g,"skin"))
  ddFace:SetList(NB_DATA:BuildRangeList(r,g,"face"))
  ddHair:SetList(NB_DATA:BuildRangeList(r,g,"hair"))
  ddHairC:SetList(NB_DATA:BuildRangeList(r,g,"haircolor"))
  ddFeat:SetList(NB_DATA:BuildRangeList(r,g,"features"))
end

  ----------------------------------------------------------------
  -- Résumé
  ----------------------------------------------------------------
local function refreshSummary()
  local race   = ddRace  :GetValue() or -1
  local gender = ddGender:GetValue() or -1
  local nom    = nameBox:GetText():gsub("^%s+",""):gsub("%s+$","")
  if nom == "" then nom = "-" end

  -- récupère chaque étiquette traduite
  local H  = i18n("SUMMARY_HEADER")
  local Nl = i18n("SUMMARY_NAME_LABEL")
  local Cl = i18n("SUMMARY_CLASS_LABEL")
  local Rl = i18n("SUMMARY_RACE_LABEL")
  local Gl = i18n("SUMMARY_GENDER_LABEL")
  local Sl = i18n("SUMMARY_SKIN_LABEL")
  local Fl = i18n("SUMMARY_FACE_LABEL")
  local Hl = i18n("SUMMARY_HAIR_LABEL")
  local Col= i18n("SUMMARY_COLOR_LABEL")
  local Fe = i18n("SUMMARY_FEAT_LABEL")
  local Ss = i18n("SUMMARY_SS_LABEL")

  -- construit le texte avec %s
  local fmt = table.concat({
    H,
    string.format("|cffffd200%s :|r %s", Nl, nom),
    string.format("|cffffd200%s :|r %s", Cl, NB_DATA.Classes[ddClass:GetValue()] or "-"),
    string.format("|cffffd200%s :|r %s", Rl, NB_DATA.Races[race] or "-"),
    string.format("|cffffd200%s :|r %s", Gl, NB_DATA.Genders[gender] or "-"),
    string.format("|cffffd200%s :|r %s", Sl, getLabel("Skin", race, tonumber(ddSkin:GetValue()))),
    string.format("|cffffd200%s :|r %s", Fl, getLabel("Face", race, tonumber(ddFace:GetValue()))),
    string.format("|cffffd200%s :|r %s", Hl, getLabel("HairStyle", race, tonumber(ddHair:GetValue()))),
    string.format("|cffffd200%s :|r %s", Col, getLabel("HairColor", race, tonumber(ddHairC:GetValue()))),
    string.format("|cffffd200%s :|r %s", Fe, getLabel("Features", race, tonumber(ddFeat:GetValue()))),
    string.format("|cffffd200%s :|r %s", Ss, NB_DATA.Soundset[ddSS:GetValue()] or "-"),
  }, "\n")

  summary:SetText(fmt)
end

  ----------------------------------------------------------------
  -- Callbacks centralisés
  ----------------------------------------------------------------
local function changed()
  fillRanges()
  refreshSummary()
end
for _,dd in ipairs{ddRace, ddGender, ddSkin, ddFace, ddHair, ddHairC, ddFeat, ddClass, ddSS} do
  dd:SetCallback("OnValueChanged", changed)
end

nameBox:SetCallback("OnTextChanged", changed)  -- pour mettre à jour le Nom
changed()  -- affichage initial
----------------------------------------------------------------

  -- Callbacks pour MAJ des ranges -------------------------------
  -- local function refreshRanges() updateVisualDropdowns(ddRace:GetValue(), ddGender:GetValue(), ddSkin, ddFace, ddHair, ddHairC, ddFeat) end
  -- ddRace:SetCallback("OnValueChanged", refreshRanges)
  -- ddGender:SetCallback("OnValueChanged", refreshRanges)

  ----------------------------------------------------------------
  -- Bouton Créer
  ----------------------------------------------------------------
  -- local btnCreate = AceGUI:Create("Button"); btnCreate:SetText(i18n("BOT_CREATE8BUTTON")); btnCreate:SetWidth(120)
  -- btnCreate:SetCallback("OnClick", function()
  --   local name = (nameBox:GetText() or ""):gsub("%s+","_")
  --   local class,race,gender = ddClass:GetValue(), ddRace:GetValue(), ddGender:GetValue()
  --   local skin,face,hair,hc,feat,ss = ddSkin:GetValue(), ddFace:GetValue(), ddHair:GetValue(), ddHairC:GetValue(), ddFeat:GetValue(), ddSS:GetValue()
  --   if name=="" or not (class and race and gender and skin and face and hair and hc and feat and ss) then
  --     print("|cffff0000[NetherBot]|r Remplissez tous les champs."); return
  --   end
  --   local cmd = string.format(".npcbot createnew %s %d %d %d %d %d %d %d %d %d", name, class, race, gender, skin, face, hair, hc, feat, ss)
  --   -- SendChatMessage(cmd, "SAY")
	 --print("Commande envoyée : " ..cmd)
  --   f:Hide()
  -- end)
  local btnCreate = AceGUI:Create("Button"); btnCreate:SetText(i18n("BOT_CREATE8BUTTON"))
  btnCreate:SetWidth(120)
btnCreate:SetCallback("OnClick", function()
  ----------------------------------------------------------------
  -- 1. Lecture brute du nom
  ----------------------------------------------------------------
  local rawName = nameBox:GetText() or ""

  -- 1.a Majuscule
  local first = rawName:sub(1,1)
  if not first:match("%u") then
    print(i18n("NAME_CAPS"))
    return
  end

  -- 1.b Pas d’espaces autorisés
  if rawName:find("%s") then
    print(i18n("NAME_UNDERSCORE"))
    return
  end

  ----------------------------------------------------------------
  -- 2. Normalisation : trim & underscores (pour safety)
  ----------------------------------------------------------------
  local name = rawName:gsub("^_+", ""):gsub("_+$", "")  -- enlève underscores adventices
  name = name:gsub("%s+", "_")                         -- encore, au cas où
  -- (mais normalement le rawName n’a plus d’espace)

  ----------------------------------------------------------------
  -- 3. Récupération des dropdowns
  ----------------------------------------------------------------
  local class  = ddClass :GetValue()
  local race   = ddRace  :GetValue()
  local gender = ddGender:GetValue()
  local skin   = ddSkin  :GetValue()
  local face   = ddFace  :GetValue()
  local hair   = ddHair  :GetValue()
  local color  = ddHairC :GetValue()
  local feat   = ddFeat  :GetValue()
  local ss     = ddSS    :GetValue()

  -- print("DEBUG values:", "name="..tostring(name), "class",class,"race",race,"gender",gender,"skin",skin,"face",face,"hair",hair,"color",color,"feat",feat,"ss",ss)

  ----------------------------------------------------------------
  -- 4. Vérification finale
  ----------------------------------------------------------------
  local missing = {}
  if name == ""                 then table.insert(missing,"Nom")     end
  if not class                  then table.insert(missing,"Classe")  end
  if not race                   then table.insert(missing,"Race")    end
  if not gender                 then table.insert(missing,"Genre")   end
  if not skin                   then table.insert(missing,"Peau")    end
  if not face                   then table.insert(missing,"Visage")  end
  if not hair                   then table.insert(missing,"Cheveux") end
  if not color                  then table.insert(missing,"Couleur") end
  if not feat                   then table.insert(missing,"Ornements") end
  if not ss                     then table.insert(missing,"Voix")    end

  if #missing > 0 then
    local msg = i18n("ERROR_MISSING_FIELDS"):format(table.concat(missing, ", "))
	print("|cffff0000[NetherBot]|r " .. msg)
    return
  end

  ----------------------------------------------------------------
  -- 5. Envoi de la commande
  ----------------------------------------------------------------
  local cmd = string.format(".npcbot createnew %s %d %d %d %d %d %d %d %d %d",
      name, class, race, gender, skin, face, hair, color, feat, ss)

  print("|cff55ff55Commande envoyée :|r", cmd)
  -- SendChatMessage(cmd, "SAY")
  f:Hide()
end)

  f:AddChild(btnCreate)

end

--------------------------------------------------------------------
--  FIN Patch Module création de Bots
--------------------------------------------------------------------

-- Foncfions pour delete un bot
StaticPopupDialogs["NB_DEL_CONFIRM"] = {
  text = "Delete current target or ID",
  button1 = "Target",
  button2 = "ID",
  OnAccept = function()
    local tgt = UnitName("target")
    if tgt then SendChatMessage(".npcbot delete free "..tgt, "SAY") end
	 -- SendChatMessage(".npcbot delete", "SAY")
  end,
  OnCancel = function()
    StaticPopup_Show("NB_DEL_ID")
  end,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
}

StaticPopupDialogs["NB_DEL_ID"] = {
  text = i18n("Enter NPCBOT ID:"),
  button1 = "Ok",
  button2 = "Cancel",
  hasEditBox = true,
  editBoxWidth = 100,
  timeout = 0, whileDead = true, hideOnEscape = true, preferredIndex = 3,
  OnAccept = function(self)
    local id = self.editBox:GetText()
    if id and id ~= "" then
      SendChatMessage(".npcbot delete id "..id, "SAY")
    end
  end,
}

StaticPopupDialogs["NB_DEL_FREE_CONFIRM"] = {
  text = i18n("ConfirmDeleteFree"),      -- clé de locale
  button1 = YES,                        -- “Oui”
  button2 = NO,                         -- “Non”
  OnAccept = function()
    SendChatMessage(".npcbot delete free", "SAY")
  end,
  timeout = 0,
  whileDead = true,
  hideOnEscape = true,
  preferredIndex = 3,
}
-- Fin fonctions

--------------------------------------------------------------------
--  BUFFER & FENÊTRE D’INFO
--------------------------------------------------------------------
local infoBuffer = {}          -- stocke toutes les lignes capturées

-- utilitaires
local function trim(s)  return (s:gsub("^%s*(.-)%s*$","%1")) end

-- 1) "Label : Valeur"
local function splitColon(line)
  local a,b = line:match("^%s*([^:]+):%s*(.+)$")
  if a and b ~= "" then return trim(a), trim(b) end
end

-- 2) "Label␠␠Valeur" ( ≥ 2 espaces / tab )
local function splitSpaces(line)
  local a,b = line:match("^%s*([^%s].-)%s%s+(.+)$")
  if a and b then return trim(a), trim(b) end
end

-- petit helper pour ne pas répéter la création d’un EditBox
function NetherBot:MakeEdit(label, text)
  local eb = AceGUI:Create("EditBox")
  eb:SetLabel(label)
  eb.label:SetTextColor(1,1,0)    -- jaune
  eb:SetText(text)
  eb.editbox:SetTextColor(1,1,1)  -- blanc
  eb:SetFullWidth(true)
  eb:DisableButton(true)
  eb:SetDisabled(true)
    -- ➜ recolore APRÈS SetDisabled
  eb.label  :SetTextColor(1, 1, 0)   -- jaune
  eb.editbox:SetTextColor(1, 1, 1)   -- blanc
  self.infoContainer:AddChild(eb)
end

--------------------------------------------------------------------
--  Ajoute un widget pour une ligne brute
--------------------------------------------------------------------
function NetherBot:AddInfoWidget(line)
  ----------------------------------------------------------
  -- 0) cas spécial : "Nom (classe : X), maître : Y"
  ----------------------------------------------------------
  if line:find("%(") and line:find(",") then
    for seg in line:gmatch("[^,]+") do
      seg = trim(seg)
      local name = seg:match("^(.-)%s*%(")
      local class = seg:match("classe%s*:%s*(%d+)")
      if name and class then                       -- "Nom (classe : X)"
        self:MakeEdit(name, "Classe "..class)
      else                                         -- "maître : Y" (ou autre)
        self:AddInfoWidget(seg)                    -- ré-analyse récursive
      end
    end
    return
  end

  ----------------------------------------------------------
  -- 1) "Label : Valeur"
  ----------------------------------------------------------
  local lbl,val = splitColon(line)
  if not lbl then                                  -- 2) sinon double-espace
    lbl,val = splitSpaces(line)
  end

  if lbl and val then
    self:MakeEdit(lbl, val)
  elseif line ~= "" then                           -- 3) simple titre/texte
    local l = AceGUI:Create("Label")
    l:SetText(line) ; l:SetColor(1,1,0) ; l:SetFullWidth(true)
    self.infoContainer:AddChild(l)
  end
end

--------------------------------------------------------------------
--  Crée / actualise la fenêtre d’info
--------------------------------------------------------------------
function NetherBot:ShowInfoWindow()
  if not self.infoFrame then
    local f = AceGUI:Create("Frame")
    f:SetTitle(i18n("Bot-Info"))
    f:SetLayout("Fill")
    f:SetWidth(480); f:SetHeight(420)
    f:SetCallback("OnClose", function(w)
      AceGUI:Release(w)
      self.infoFrame, self.infoContainer = nil, nil
    end)
    local scroll = AceGUI:Create("ScrollFrame")
    scroll:SetLayout("List"); scroll:SetFullWidth(true); scroll:SetFullHeight(true)
    f:AddChild(scroll)
    self.infoFrame, self.infoContainer = f, scroll
  end

  self.infoContainer:ReleaseChildren()         -- on repart d’un conteneur vide
  for _,ln in ipairs(infoBuffer) do
    self:AddInfoWidget(ln)
  end
  self.infoFrame:Show()
end

--------------------------------------------------------------------
--  Capture des messages affichés dans la fenêtre de chat
--------------------------------------------------------------------
function NetherBot:OnChatMsg(_, msg)
  table.insert(infoBuffer, msg)
  if self.infoContainer then          -- si la fenêtre est ouverte, live-update
    self:AddInfoWidget(msg)
  end
end

-- inscription aux événements (dans OnEnable)
-- self:RegisterEvent("CHAT_MSG_SAY"   , "OnChatMsg")
-- self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMsg")

-- FIN CAPTURE

-- ---------- DB & slash ----------
--function NetherBot:OnInitialize()
--  self.db = LibStub("AceDB-3.0"):New("NetherbotDB", { profile = { scale = 1 } })
--end
function NetherBot:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("NetherbotDB", {
    profile = {
      scale       = 1,
      minimapIcon = { hide = false },
    },
  })
end

-- 3) Créez l’objet LDB
local dataObj = LDB:NewDataObject("NetherBot", {
  type = "launcher",
  icon = "Interface\\Icons\\INV_Misc_EngGizmos_20",
  OnClick = function(_, button)
    if button == "LeftButton" then
      -- si la fenêtre existe déjà, on la ferme, sinon on l’ouvre
      if NetherBot.gui then
        NetherBot:HideGUI()
      else
        NetherBot:ShowGUI()
      end
    else
      NetherBot:ToggleRaid()
    end
  end,
  OnTooltipShow = function(tt)
    tt:AddLine("NetherBot")
    tt:AddLine("Left-clic : Ouvrir/Fermer le GUI", 1,1,1)
    tt:AddLine("Clic-droit : Toggle Raid-Frame",1,1,1)
  end,
})

-- function NetherBot:OnEnable()
--   self:RegisterChatCommand("netherbot", "HandleSlash")
--   self:RegisterEvent("CHAT_MSG_SAY"   , "OnChatMsg")
--   self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMsg")
-- end
function NetherBot:OnEnable()
   self:RegisterChatCommand("netherbot", "HandleSlash")
   self:RegisterEvent("CHAT_MSG_SAY"   , "OnChatMsg")
   self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMsg")
  self.db = LibStub("AceDB-3.0"):New("NetherbotDB", {
    profile = { minimapIcon = { hide = false } }
  })
  LDBIcon:Register("NetherBot", dataObj, self.db.profile.minimapIcon)
end

-- Optionnel : commande pour toggle l’icône
function NetherBot:ToggleMinimap()
  local iconDB = self.db.profile.minimapIcon
  iconDB.hide = not iconDB.hide
  LDBIcon:Refresh("NetherBot")
end
NetherBot:RegisterChatCommand("nbminimap", "ToggleMinimap")

-- 2) handler unifié
function NetherBot:OnChatMsg(_, msg)
  table.insert(infoBuffer, msg)           -- on mémorise
  -- si la fenêtre est ouverte, on ajoute la ligne à chaud
  if self.infoContainer then
    self:AddInfoWidget(msg)
  end
end

function NetherBot:HandleSlash(msg)
  msg = (msg or ""):lower()
  if msg == "show"      then self:ShowGUI()
  elseif msg == "hide"  then self:HideGUI()
  else self:Print("/netherbot show  –  /netherbot hide") end
end

-- ▶ pré-déclaration pour que Lua sache qu’il existe localement
-- local initializeFramesAndBars
initializeFramesAndBars = nil

-- ---------- helpers ----------
-- local function addButton(parent, label, w, cb)
--   local b = AceGUI:Create("Button")
--   b:SetText(label); b:SetWidth(w or 110)
--   b:SetCallback("OnClick", cb)
--   parent:AddChild(b)
-- end

-- Maintenant avec un paramètre tooltipText en option
local function addButton(parent, label, w, cb, tooltipText)
  local b = AceGUI:Create("Button")
  b:SetText(label)
  b:SetWidth(w or 110)
  b:SetCallback("OnClick", cb)

  -- si on a un texte de tooltip, on branche GameTooltip
  if tooltipText then
    b:SetCallback("OnEnter", function(widget)
      GameTooltip:SetOwner(widget.frame, "ANCHOR_RIGHT")
      GameTooltip:SetText(label)                     -- titre du tooltip
      GameTooltip:AddLine(tooltipText, 1,1,1, true)   -- description
      GameTooltip:Show()
    end)
    b:SetCallback("OnLeave", function()
      GameTooltip:Hide()
    end)
  end

  parent:AddChild(b)
  return b
end


-- helper amélioré
-- local function addButton(parent, label, widthOrCb, maybeCb)
--   local cb, minWidth
--   if type(widthOrCb) == "function" then
--     -- signature (parent, label, cb)
--     cb       = widthOrCb
--     minWidth = 0
--   else
--     -- signature (parent, label, minWidth, cb)
--     minWidth = widthOrCb or 0
--     cb       = maybeCb
--   end
-- 
--   -- création et labellisation
--   local b = AceGUI:Create("Button")
--   b:SetText(label)
--   b:SetCallback("OnClick", cb)
--   parent:AddChild(b)
-- 
--   -- **ici** on récupère bien le FS interne  
--   -- (c’est celui qu’AceGUI a créé pour afficher le texte)
--   local fs = b.text or b.button:GetFontString()
--   local textWidth = fs:GetStringWidth()
-- 
--   -- marge « padding » à gauche+droite, ajustez si besoin
--   local padding = 24  
--   local finalW = math.max(textWidth + padding, minWidth)
-- 
--   b:SetWidth(finalW)
-- 
--   -- on refait le layout Flow si besoin
--   if parent.type == "Flow" then
--     parent:DoLayout()
--   end
--   
--   return b
-- end

-- ---------- main GUI ----------
function NetherBot:ShowGUI()
if self.gui then                  -- le widget existe déjà
    self.gui:Show()               -- on le ré-affiche
    return
end

  local f = AceGUI:Create("Frame")
  f:SetTitle(i18n("NetherBot_title")); f:SetStatusText("v1.0")
  f:SetLayout("Flow")          -- ① on repasse en Flow
  f:SetWidth(400); f:SetHeight(300)
  f.frame:SetResizable(true); f.frame:SetMinResize(400,300)
  f.frame:SetScale(self.db.profile.scale or 1)
  f:SetCallback("OnClose", function(w)
    AceGUI:Release(w)
    self.gui = nil                -- signale que le widget n’existe plus
end)
  self.gui = f
  -- RÉCUPÈRE la frame qu’on a créée plus bas
  local af = _G["NetherbotAdminFrame"]
  if af then
    af:ClearAllPoints()
    af:SetPoint("LEFT", f.frame, "RIGHT", 10, 0)
  end

  -------------------------------------------------- ligne 1
  addButton(f,i18n("Follow"),90,function() SendChatMessage(".npcbot command follow","SAY") end, i18n("Follow_tooltip"))
  addButton(f,i18n("Stand"), 90,function() SendChatMessage(".npcbot command standstill","SAY") end, i18n("Stand_tooltip"))
  addButton(f,i18n("Stop"),  90,function() SendChatMessage(".npcbot command stopfully","SAY") end, i18n("Stop_tooltip"))
  addButton(f,i18n("Slack"), 90,function() SendChatMessage(".npcbot command follow only","SAY") end, i18n("Slack_tooltip"))

  local sep = AceGUI:Create("Heading"); sep:SetFullWidth(true); f:AddChild(sep)

  -------------------------------------------------- ligne 2
  addButton(f,i18n("UnHide"),90,function() SendChatMessage(".npcbot unhide","SAY") end, i18n("UnHide_tooltip"))
  addButton(f,i18n("Hide"),  90,function() SendChatMessage(".npcbot hide","SAY") end, i18n("Hide_tooltip"))
  addButton(f,i18n("Recall"),90,function() SendChatMessage(".npcbot recal teleport","SAY") end, i18n("Recall_tooltip"))
  addButton(f,i18n("Unbind"),90,function() SendChatMessage(".npcbot command unbind","SAY") end, i18n("Unbind_tooltip"))

  sep = AceGUI:Create("Heading"); sep:SetFullWidth(true); f:AddChild(sep)

  -------------------------------------------------- ligne 3
  addButton(f,"Dist 30",90,function() SendChatMessage(".npcbot distance 30","SAY") end, i18n("Dist_30_tooltip"))
  addButton(f,"Dist 50",90,function() SendChatMessage(".npcbot distance 50","SAY") end, i18n("Dist_50_tooltip"))
  addButton(f,"Dist 85",90,function() SendChatMessage(".npcbot distance 85","SAY") end, i18n("Dist_85_tooltip"))

  sep = AceGUI:Create("Heading"); sep:SetFullWidth(true); f:AddChild(sep)

  -------------------------------------------------- ligne 4
  addButton(f,i18n("Spawn Bot"),120,function() self:SpawnDialog() end, i18n("Spanw_bot_tooltip"))
  addButton(f,i18n("Revive"),    120,function() SendChatMessage(".npcbot revive","SAY") end, i18n("Revive_tooltip"))

  sep = AceGUI:Create("Heading"); sep:SetFullWidth(true); f:AddChild(sep)

  -------------------------------------------------- ligne 5
  addButton(f,i18n("Admin"), 80,function() ToggleFrame(NetherbotAdminFrame) end, i18n("Admin_tooltip"))
  addButton(f,"Lookup",      80,function() ToggleFrame(NetherbotLookupFrame) end, i18n("Lookup_tooltip"))
  addButton(f,"RaidFrame",   120,function()
                               if TeamFrame:IsShown() then TeamFrame:Hide()
                               else initializeFramesAndBars(); TeamFrame:Show() end
                             end, i18n("Raidframe_tooltip"))
end


function NetherBot:HideGUI()
  if self.gui then self.gui:Hide() end
end

-- ---------- spawn dialog ----------
function NetherBot:SpawnDialog()
  local dlg = AceGUI:Create("Frame")
  dlg:SetTitle(i18n("Spawn Bot"))
  dlg:SetWidth(200); dlg:SetHeight(110)
  dlg:SetLayout("Flow")

  local eb = AceGUI:Create("EditBox")
  eb:SetLabel(i18n("Entry ID")); eb:SetWidth(160)
  dlg:AddChild(eb)

  local ok = AceGUI:Create("Button")
  ok:SetText("OK"); ok:SetWidth(60)
  ok:SetCallback("OnClick", function()
    local id = eb:GetText()
    if id ~= "" then SendChatMessage(".npcbot spawn "..id, "SAY") end
    dlg:Release()
  end)
  dlg:AddChild(ok)
end

--------------------------------------------------------------------
--  CADRE ADMIN  (inchangé, ancré à l’écran)
--------------------------------------------------------------------
local adminFrame = CreateFrame("Frame", "NetherbotAdminFrame", UIParent)
adminFrame:SetSize(280, 200)
-- adminFrame:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
adminFrame:SetBackdrop({
  bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
  tile     = true, tileSize = 16, edgeSize = 16,
  insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
adminFrame:SetBackdropColor(1, 0, 0, 0.2)
adminFrame:SetBackdropBorderColor(0, 1, 0, 1)
adminFrame:Hide()

local adminTitle = adminFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
adminTitle:SetPoint("TOP", 0, -10)
adminTitle:SetText(i18n("Admin"))

-- Bouton “X” standard pour fermer la fenêtre
local closeAdmin = CreateFrame("Button", nil, adminFrame, "UIPanelCloseButton")
closeAdmin:SetPoint("TOPRIGHT", adminFrame, "TOPRIGHT", -6, -6)
closeAdmin:SetScript("OnClick", function()
  adminFrame:Hide()
end)

-- ---------- boutons Admin ----------
local function makeAdminBtn(name, text, x, y, width, tooltipText)
  local b = CreateFrame("Button", name, adminFrame, "UIPanelButtonTemplate")
  b:SetSize(width or 60, 22)
  b:SetPoint("TOPLEFT", x, y)
  b:SetText(i18n(text))
  b:GetNormalTexture():SetVertexColor(0.10, 1.00, 0.10)

  if tooltipText then
    b:SetScript("OnEnter", function(self)
      GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
      GameTooltip:SetText(i18n(text), 1,1,0)
      GameTooltip:AddLine(tooltipText, 1,1,1, true)
      GameTooltip:Show()
    end)
    b:SetScript("OnLeave", GameTooltip_Hide)
  end

  return b
end

local bAdd    = makeAdminBtn("NB_Add"   , "Add"     , 10 , -35 , 70, i18n("Add_tooltip"))
local bRemove = makeAdminBtn("NB_Remove", "Remove"  , 10 , -62 , 70, i18n("Remove_tooltip"))
local bRecall   = makeAdminBtn("NB_Recall"  , "Recall"  , 85 , -35 , 70, i18n("Recall_tooltip"))
local bInfo     = makeAdminBtn("NB_Info"    , "Bot-Info", 160, -35 , 70, i18n("Info_tooltip"))
local bMove     = makeAdminBtn("NB_Move"    , "Move"    , 85 , -62 , 70, i18n("Move_tooltip"))
local bDelete   = makeAdminBtn("NB_Delete"  , "Delete"  , 160, -62 , 70, i18n("Delete_tooltip"))
-- bouton “Delete Free” (supprime tous les bots libres)
local bDeleteFree = makeAdminBtn("NB_DeleteFree", "Delete Free", 10, -89, 155, i18n("DeleteFree_tooltip"))-- 4. Add a button on the admin panel (after existing makeAdminBtn calls)
-- 4. Add a button on the admin panel (after existing makeAdminBtn calls)
local bCreateBot = makeAdminBtn("NB_CreateBot", "CREATE_BOT", 170, -89, 90, i18n("CREATE_BOT_TOOLTIP"))
bCreateBot:SetScript("OnClick", function() NetherBot:ShowCreateBotFrame() end)

--  142,              -- x = 142px à droite du coin top-left de adminFrame
--  -62,              -- y = 62px vers le bas du coin top-left de adminFrame
--  70,               -- largeur du bouton en pixels
  
bDeleteFree:SetScript("OnClick", function()
  StaticPopup_Show("NB_DEL_FREE_CONFIRM")
end)

bAdd   :SetScript("OnClick", function()
  local target = UnitName("target")
  if target then
	SendChatMessage(".npcbot add ", "SAY")
  else
    StaticPopupDialogs["NB_ADD"] = {
      text = i18n("Enter NPCBOT ID:"),
      button1 = "Ok", button2 = "Cancel",
      hasEditBox = true, timeout = 0,
      whileDead = true, hideOnEscape = true,
      OnAccept = function(self)
        local id = self.editBox:GetText()
        SendChatMessage(".npcbot add "..id, "SAY")
      end,
    }
    StaticPopup_Show("NB_ADD")
  end
end)

bRemove:SetScript("OnClick", function()
  local target = UnitName("target")
  if target then
    SendChatMessage(".npcbot remove "..target, "SAY")
  else
    StaticPopupDialogs["NB_REM"] = {
      text = i18n("Enter NPCBOT ID:"),
      button1 = "Ok", button2 = "Cancel",
      hasEditBox = true, timeout = 0,
      whileDead = true, hideOnEscape = true,
      OnAccept = function(self)
        local id = self.editBox:GetText()
        SendChatMessage(".npcbot remove "..id, "SAY")
      end,
    }
    StaticPopup_Show("NB_REM")
  end
end)

bRecall:SetScript("OnClick", function() SendChatMessage(".npcbot recall", "SAY") end)

bInfo  :SetScript("OnClick", function() 
  -- reset buffer & affiche la fenêtre
  wipe(infoBuffer)
  NetherBot:ShowInfoWindow()
  -- envoie la commande au bot
  SendChatMessage(".npcbot info",   "SAY") 
  DoEmote("BONK") 
end)

bMove  :SetScript("OnClick", function() SendChatMessage(".npcbot move",   "SAY") end)

-- bDelete:SetScript("OnClick", function()
--   StaticPopupDialogs["NB_DEL_CONFIRM"] = {
--     text = "Delete current target or ID",
--     button1 = "Target", button2 = "ID",
--     OnAccept = function()
--       local tgt = UnitName("target")
--       if tgt then SendChatMessage(".npcbot delete "..tgt, "SAY") end
--     end,
--     OnCancel = function()
--       StaticPopupDialogs["NB_DEL_ID"] = {
--         text = i18n("Enter NPCBOT ID:"),
--         button1 = "Ok", button2 = "Cancel",
--         hasEditBox = true, timeout = 0,
--         whileDead = true, hideOnEscape = true,
--         OnAccept = function(self)
--           local id = self.editBox:GetText()
--           SendChatMessage(".npcbot delete "..id, "SAY")
--         end,
--       }
--       StaticPopup_Show("NB_DEL_ID")
--     end,
--     timeout = 0, whileDead = true, hideOnEscape = true,
--   }
--   StaticPopup_Show("NB_DEL_CONFIRM")
-- end)
bDelete:SetScript("OnClick", function()
  StaticPopup_Show("NB_DEL_CONFIRM")
end)

--  Sort Resu rapide
local redemptionButton = CreateFrame("Button", "NB_RedemptionButton", adminFrame, "SecureActionButtonTemplate")
redemptionButton:SetSize(30, 30)
redemptionButton:SetPoint("BOTTOMLEFT", 10, 10)
local ic = redemptionButton:CreateTexture(nil, "BACKGROUND")
ic:SetAllPoints()
ic:SetTexture(select(3, GetSpellInfo(7328)))
redemptionButton:SetNormalTexture(ic)
redemptionButton:SetAttribute("type", "spell")
redemptionButton:SetAttribute("spell", 7328)
redemptionButton:SetScript("OnEnter", function(self)
  GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  GameTooltip:SetText(i18n("Revive Bots"))
end)
redemptionButton:SetScript("OnLeave", GameTooltip_Hide)
redemptionButton:SetScript("OnClick", function() SendChatMessage(".npcbot revive", "SAY") end)

--------------------------------------------------------------------
--  CADRE LOOKUP  (choix de classe, spawn rapide)
--------------------------------------------------------------------
local lookupFrame = CreateFrame("Frame", "NetherbotLookupFrame", UIParent)
lookupFrame:SetSize(200, 260)
-- lookupFrame:SetPoint("CENTER")
lookupFrame:SetBackdrop({
  bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
  tile     = true, tileSize = 16, edgeSize = 16,
  insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
lookupFrame:SetBackdropColor(0, 0, 1, 0.25)
lookupFrame:SetBackdropBorderColor(0, 0, 1, 1)
lookupFrame:Hide()
-- repositionne dynamiquement à l’ouverture
lookupFrame:HookScript("OnShow", function(self)
  self:ClearAllPoints()
  if adminFrame and adminFrame:IsShown() then
    -- si admin est visible, colle lookup à sa droite
    self:SetPoint("TOPLEFT", adminFrame, "TOPRIGHT", 10, 0)
  elseif NetherBot.gui and NetherBot.gui.frame then
    -- sinon si la GUI principale est visible, colle lookup à sa droite
    self:SetPoint("TOPLEFT", NetherBot.gui.frame, "TOPRIGHT", 10, 0)
  else
    -- fallback : centre à l’écran
    self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
  end
end)

lookupFrame:SetMovable(true)
lookupFrame:EnableMouse(true)
lookupFrame:RegisterForDrag("LeftButton")
lookupFrame:SetScript("OnDragStart", lookupFrame.StartMoving)
lookupFrame:SetScript("OnDragStop",  lookupFrame.StopMovingOrSizing)

local lkTitle = lookupFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
lkTitle:SetPoint("TOP", 0, -6)
lkTitle:SetText(i18n("Select class"))

--  ScrollFrame
local scroll = CreateFrame("ScrollFrame", "NB_LookupScroll", lookupFrame, "UIPanelScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", 4, -25)
scroll:SetPoint("BOTTOMRIGHT", -26, 8)

local list = CreateFrame("Frame", nil, scroll)
list:SetSize(160, 800)
scroll:SetScrollChild(list)

--  table <Nom FR> = entry
local classTable = {
  ["Warrior"]=1, ["Paladin"]=2, ["Hunter"]=3, ["Rogue"]=4, ["Priest"]=5,
  ["Death Knight"]=6, ["Shaman"]=7, ["Mage"]=8, ["Warlock"]=9, ["Druid"]=11,
  ["Blademaster"]=12, ["Sphynx"]=13, ["Archmage"]=14, ["Dreadlord"]=15,
  ["Spellbreaker"]=16, ["DarkRanger"]=17, ["Necromancer"]=18, ["SeaWitch"]=19
}

local idx = 0
for cls, id in pairs(classTable) do
  idx = idx + 1
  local b = CreateFrame("Button", nil, list, "UIPanelButtonTemplate")
  b:SetSize(140, 22)
  b:SetPoint("TOP", 0, -2 - (idx-1)*24)
  b:SetText(i18n(cls))
  b:GetNormalTexture():SetVertexColor(0.10,1.00,0.10)
  b:SetScript("OnClick", function() SendChatMessage(".npcbot lookup "..id, "SAY") end)
end

--  Bouton fermer
local closeLk = CreateFrame("Button", nil, lookupFrame, "UIPanelButtonTemplate")
closeLk:SetSize(20, 18)
closeLk:SetPoint("TOPRIGHT", -6, -6)
closeLk:SetText("X")
closeLk:GetNormalTexture():SetVertexColor(1,0.2,0.2)
closeLk:SetScript("OnClick", function() lookupFrame:Hide() end)

--  Sous-cadre Spawn direct par ID
local spawnFrame = CreateFrame("Frame", nil, lookupFrame)
spawnFrame:SetSize(180, 50)
spawnFrame:SetPoint("BOTTOM", 0, -60)
spawnFrame:SetBackdrop({
  bgFile="Interface/BUTTONS/WHITE8X8", edgeFile="Interface/BUTTONS/WHITE8X8",
  edgeSize=1, insets={0,0,0,0}
})
spawnFrame:SetBackdropColor(0,0,1,0.15)
spawnFrame:SetBackdropBorderColor(0,0,1,1)

local spTitle = spawnFrame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
spTitle:SetPoint("TOPLEFT", 8, -6)
spTitle:SetText(i18n("Spawn BOT ID:"))

local idBox = CreateFrame("EditBox", nil, spawnFrame, "InputBoxTemplate")
idBox:SetSize(70,18)
idBox:SetPoint("BOTTOMLEFT", 10, 8)
idBox:SetAutoFocus(false)

local spBtn = CreateFrame("Button", nil, spawnFrame, "UIPanelButtonTemplate")
spBtn:SetSize(70,20)
spBtn:SetPoint("LEFT", idBox, "RIGHT", 6, 0)
spBtn:SetText(i18n("Spawn"))
spBtn:GetNormalTexture():SetVertexColor(0.10,1.00,0.10)
spBtn:SetScript("OnClick", function()
  local id = idBox:GetText()
  if id ~= "" then
    SendChatMessage(".npcbot spawn "..id, "SAY")
    idBox:SetText("")
    idBox:ClearFocus()
  end
end)

--------------------------------------------------------------------
--  RAID FRAME (TeamFrame) – code original conservé
--------------------------------------------------------------------
-- local TeamFrame = CreateFrame("Frame", "TeamFrame", UIParent)
TeamFrame = CreateFrame("Frame", "TeamFrame", UIParent)
TeamFrame:SetSize(350, 600)
TeamFrame:SetPoint("CENTER")
TeamFrame:Hide()

TeamFrame:SetMovable(true)
TeamFrame:EnableMouse(true)
TeamFrame:RegisterForDrag("LeftButton")
TeamFrame:SetScript("OnDragStart", TeamFrame.StartMoving)
TeamFrame:SetScript("OnDragStop",  TeamFrame.StopMovingOrSizing)

--  tables
local memberFrames, healthBars, manaBars, nameTexts, groupFrames = {},{},{},{},{}
------------------------------------------------
-- function initializeFramesAndBars()
initializeFramesAndBars = function()
  if not RAID_CLASS_COLORS then return end

  -- clear
  for _,f in ipairs(memberFrames) do f:Hide() end
  wipe(memberFrames); wipe(healthBars); wipe(manaBars); wipe(nameTexts); wipe(groupFrames)

  local n = GetNumRaidMembers()
  for i=1,n do
    local grp  = math.ceil(i/5)
    local pos  = i - ((grp-1)*5)
    if pos==1 then
      local gf = CreateFrame("Frame", nil, TeamFrame)
      gf:SetSize(80,20)
      local col = (grp-1)%2
      local row = math.floor((grp-1)/2)
      gf:SetPoint("TOPLEFT", TeamFrame, "TOP", 175*(col-1), 10 - row*230)
      gf:SetBackdrop({edgeFile="Interface/Tooltips/UI-Tooltip-Border", tile=true, tileSize=16, edgeSize=16,insets={4,4,4,4}})
      local t = gf:CreateFontString(nil,"OVERLAY","GameFontNormal")
      t:SetPoint("TOP",0,-3)
      t:SetText("Group "..grp)
      groupFrames[grp] = gf
    end

    local col,row = (grp-1)%2, math.floor((grp-1)/2)
    local mf = CreateFrame("Button", nil, TeamFrame, "SecureUnitButtonTemplate")
    mf:SetSize(150,42)
    mf:SetPoint("TOPLEFT", TeamFrame, "TOPLEFT", 10+175*col, -10-((row*230)+(pos-1)*42))
    mf:SetAttribute("unit", "raid"..i)
    mf:RegisterForClicks("AnyUp")
    SecureUnitButton_OnLoad(mf, "raid"..i)
    mf:SetBackdrop({bgFile="Interface/Tooltips/UI-Tooltip-Background",edgeFile="Interface/Tooltips/UI-Tooltip-Border",tile=true,tileSize=16,edgeSize=16,insets={4,4,4,4}})
    local _,class = UnitClass("raid"..i)
    local cc = RAID_CLASS_COLORS[class] or {r=1,g=1,b=1}
    mf:SetBackdropBorderColor(cc.r,cc.g,cc.b,0.8)
    mf:SetBackdropColor(cc.r,cc.g,cc.b,0.2)

    local pn = UnitName("raid"..i)
    local name = mf:CreateFontString(nil,"OVERLAY","GameFontNormal")
    name:SetPoint("TOP",5,-5)
    name:SetText(pn)
    name:SetTextColor(cc.r,cc.g,cc.b)

    local hp = CreateFrame("StatusBar", nil, mf)
    hp:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    hp:SetPoint("TOP", name, "BOTTOM", 0, -2)
    hp:SetSize(100,8)
    hp:SetMinMaxValues(0, UnitHealthMax("raid"..i))
    hp:SetValue(UnitHealth("raid"..i))

    local mp = CreateFrame("StatusBar", nil, mf)
    mp:SetStatusBarTexture("Interface\\TARGETINGFRAME\\UI-StatusBar")
    mp:SetStatusBarColor(0,0,1)
    mp:SetPoint("TOP", hp, "BOTTOM", 0, 0)
    mp:SetSize(100,8)
    mp:SetMinMaxValues(0, UnitPowerMax("raid"..i))
    mp:SetValue(UnitPower("raid"..i))

    memberFrames[i]=mf; healthBars[i]=hp; manaBars[i]=mp; nameTexts[i]=name
  end
end

local function updateHealthMana(_,_,unit)
  for i=1,#healthBars do
    if unit=="raid"..i then
      healthBars[i]:SetMinMaxValues(0, UnitHealthMax(unit))
      healthBars[i]:SetValue(UnitHealth(unit))
      manaBars[i]:SetMinMaxValues(0, UnitPowerMax(unit))
      manaBars[i]:SetValue(UnitPower(unit))
    end
  end
end

TeamFrame:RegisterEvent("UNIT_HEALTH")
TeamFrame:RegisterEvent("UNIT_POWER_UPDATE")
TeamFrame:RegisterEvent("RAID_ROSTER_UPDATE")
TeamFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
TeamFrame:SetScript("OnEvent", function(self, event, unit)
  if event=="RAID_ROSTER_UPDATE" or event=="PLAYER_ENTERING_WORLD" then
    initializeFramesAndBars()
  else
    updateHealthMana(self,event,unit)
  end
end)

function NetherBot:ToggleRaid()
  if TeamFrame:IsShown() then TeamFrame:Hide() else initializeFramesAndBars(); TeamFrame:Show() end
end
NetherBot:RegisterChatCommand("nbraid", "ToggleRaid")