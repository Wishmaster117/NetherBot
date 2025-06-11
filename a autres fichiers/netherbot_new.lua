--------------------------------------------------------------------
--  NetherBot – Ace3 (3.3.5a)  •  locale-safe + scale-fix
--------------------------------------------------------------------
local AceAddon   = LibStub("AceAddon-3.0")
local AceConsole = LibStub("AceConsole-3.0")
local AceEvent   = LibStub("AceEvent-3.0")
local AceGUI     = LibStub("AceGUI-3.0")
local AceLocale = LibStub("AceLocale-3.0")



-- 1) CRÉATION DE L’ADDON (doit venir en tout début)
local NetherBot = AceAddon:NewAddon("NetherBot", "AceConsole-3.0", "AceEvent-3.0")

-- 2) Chargement des locales & utilitaires
local L = AceLocale:GetLocale("NetherBot")
local function i18n(key)
  return (L and L[key]) or key
end

-- NetherBot.i18n = i18n               -- (optionnel) pour l’utiliser ailleurs

--------------------------------------------------------------------
--  BUFFER & FENÊTRE D’INFO
--------------------------------------------------------------------
-- table globale (pour accumuler les lignes reçues)
local infoBuffer = {}

-- Crée (ou ré-affiche) la fenêtre d’info
function NetherBot:ShowInfoWindow()
  -- si déjà ouvert, on remet à jour le texte
  if self.infoFrame then
    self.infoFrame:Show()
    self.infoEdit:SetText(table.concat(infoBuffer, "\n"))
    return
  end

  -- créé la frame principale
  local f = AceGUI:Create("Frame")
  f:SetTitle(i18n("Bot-Info"))       -- pensez à ajouter L["Bot-Info"] dans vos locales
  f:SetLayout("Fill")
  f:SetWidth(400); f:SetHeight(300)
  f:SetCallback("OnClose", function(widget)
    AceGUI:Release(widget)
    self.infoFrame = nil
    self.infoEdit  = nil
  end)

  -- créé l’EditBox multi‐ligne pour y coller le chat
  local eb = AceGUI:Create("MultiLineEditBox")
  eb:DisableButton(true)
  eb:SetLabel("")                    -- pas de label au-dessus
  eb:SetFullWidth(true); eb:SetFullHeight(true)
  eb:SetText(table.concat(infoBuffer, "\n"))

  f:AddChild(eb)

  -- on conserve les refs pour mise à jour ultérieure
  self.infoFrame = f
  self.infoEdit  = eb
end

-- Capture les messages en /say
function NetherBot:CHAT_MSG_SAY(event, msg, author, ...)
  -- si vous voulez filtrer sur l’auteur :
  -- if author ~= UnitName("player") then
    table.insert(infoBuffer, msg)
    if self.infoEdit then
      self.infoEdit:SetText(table.concat(infoBuffer, "\n"))
    end
  -- end
end

-- FIN CAPTURE

-- ---------- DB & slash ----------
function NetherBot:OnInitialize()
  self.db = LibStub("AceDB-3.0"):New("NetherbotDB", { profile = { scale = 1 } })
end

function NetherBot:OnEnable()
  self:RegisterChatCommand("netherbot", "HandleSlash")
    -- on écoute les messages en /say
  self:RegisterEvent("CHAT_MSG_SAY")
  self:RegisterEvent("CHAT_MSG_SYSTEM", "OnChatMsg")
end

-- 2) handler unifié
function NetherBot:OnChatMsg(event, msg, author, ...)
  table.insert(infoBuffer, msg)
  if self.infoEdit then
    self.infoEdit:SetText(table.concat(infoBuffer, "\n"))
  end
end

function NetherBot:HandleSlash(msg)
  msg = (msg or ""):lower()
  if msg == "show"      then self:ShowGUI()
  elseif msg == "hide"  then self:HideGUI()
  else self:Print("/netherbot show  –  /netherbot hide") end
end

-- ▶ pré-déclaration pour que Lua sache qu’il existe localement
local initializeFramesAndBars

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
adminFrame:SetSize(300, 200)
adminFrame:SetPoint("CENTER", UIParent, "CENTER", 220, 0)
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

-- ---------- boutons Admin ----------
local function makeAdminBtn(name, text, x, y, width)
    local b = CreateFrame("Button", name, adminFrame, "UIPanelButtonTemplate")
    b:SetSize(width or 60, 22)
    b:SetPoint("TOPLEFT", x, y)
    b:SetText( i18n(text) )      -- ← text, plus label
    b:GetNormalTexture():SetVertexColor(0.10, 1.00, 0.10)
    return b
end

local bAdd      = makeAdminBtn("NB_Add"     , "Add"     , 10 , -35)
local bRemove   = makeAdminBtn("NB_Remove"  , "Remove"  , 10 , -62 , 70)
local bRecall   = makeAdminBtn("NB_Recall"  , "Recall"  , 80 , -35 , 60)
local bInfo     = makeAdminBtn("NB_Info"    , "Bot-Info", 142, -35 , 70)
local bMove     = makeAdminBtn("NB_Move"    , "Move"    , 80 , -62 , 60)
local bDelete   = makeAdminBtn("NB_Delete"  , "Delete"  , 142, -62 , 65)

bAdd   :SetScript("OnClick", function()
  local target = UnitName("target")
  if target then
    SendChatMessage(".npcbot add "..target, "SAY")
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

bDelete:SetScript("OnClick", function()
  StaticPopupDialogs["NB_DEL_CONFIRM"] = {
    text = "Delete current target or ID",
    button1 = "Target", button2 = "ID",
    OnAccept = function()
      local tgt = UnitName("target")
      if tgt then SendChatMessage(".npcbot delete "..tgt, "SAY") end
    end,
    OnCancel = function()
      StaticPopupDialogs["NB_DEL_ID"] = {
        text = i18n("Enter NPCBOT ID:"),
        button1 = "Ok", button2 = "Cancel",
        hasEditBox = true, timeout = 0,
        whileDead = true, hideOnEscape = true,
        OnAccept = function(self)
          local id = self.editBox:GetText()
          SendChatMessage(".npcbot delete "..id, "SAY")
        end,
      }
      StaticPopup_Show("NB_DEL_ID")
    end,
    timeout = 0, whileDead = true, hideOnEscape = true,
  }
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
lookupFrame:SetPoint("CENTER")
lookupFrame:SetBackdrop({
  bgFile   = "Interface/Tooltips/UI-Tooltip-Background",
  edgeFile = "Interface/Tooltips/UI-Tooltip-Border",
  tile     = true, tileSize = 16, edgeSize = 16,
  insets   = { left = 4, right = 4, top = 4, bottom = 4 }
})
lookupFrame:SetBackdropColor(0, 0, 1, 0.25)
lookupFrame:SetBackdropBorderColor(0, 0, 1, 1)
lookupFrame:Hide()

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
local TeamFrame = CreateFrame("Frame", "TeamFrame", UIParent)
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