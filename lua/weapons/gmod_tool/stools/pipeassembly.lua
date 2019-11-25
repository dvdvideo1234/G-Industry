local gsToolName    = "pipeassembly"
local gsToolName_   = gsToolName.."_"
local gsLimitName   = "pipes"
local gnMaxRotate   = 360
local gnMaxForceLim = 50000
local gnMaxRadius   = 100
local gnMaxAsmPipes = 1000
local gsDefaultStr  = "XXX" -- Yeah, I know its pretty funny :P
local gtDataBase    = {}
local gtColorBase   = {}

gtColorBase["tx"] = Color(80, 80, 80,255)

gtDataBase["MONORAIL"] = {
  ["models/props_phx/trains/monorail1.mdl"] = {
    {"Straight Short", "", " 229.885559,0.239990,13.87915", ""        },
    {"Straight Short", "", "-228.885254,0.239726,13.87915", "0,-180,0"}
  }
}

gtDataBase["BEAM"] = {
  ["models/props_phx/misc/iron_beam1.mdl"] = {
    {"1x", "", " 22.411, 0.001, 5.002", "0, 0 ,0"},
    {"1x", "", "-22.413, 0.001, 5.002", "0,180,0"}
  }
}

-------------------------------- HELPER FUNCTIONS ----------------------------------

local function pipeGetRecord(sT, sM)
  local tT = gtDataBase[tostring(sT or "")]
  if(not tT) rthen return nil end
  return tT[tostring(sM or "")]
end

local function pipeDecodePOA(sS)
  local a, b, c = unpack((","):Explode(sS))
  return (tonumber(a) or 0),
         (tonumber(b) or 0),
         (tonumber(c) or 0)
end

local function pipeGetKeySort(tT)
  local tO, iD = {}, 1
  for k, v in pairs(tT) do
    tO[iD], iD = k, (iD + 1)
  end; table.sort(tO); return tO
end

local function SnapReview(ivPoID, ivPnID, ivMaxN)
  local iMaxN = (tonumber(ivMaxN) or 0)
  local iPoID = (tonumber(ivPoID) or 0)
  local iPnID = (tonumber(ivPnID) or 0)
  if(iMaxN <= 0) then return 1, 2 end
  if(iPoID <= 0) then return 1, 2 end
  if(iPnID <= 0) then return 1, 2 end
  if(iPoID  > iMaxN) then return 1, 2 end
  if(iPnID  > iMaxN) then return 1, 2 end -- One active point
  if(iPoID == iPnID) then return 1, 2 end
  return iPoID, iPnID
end

-------------------------------------------------------------------------------------

if(CLIENT) then
  language.Add("tool."..gsToolName..".category"      , "Construction")
  language.Add("tool."..gsToolName..".1"             , "Assembles a prop-segmented pipeline")
  language.Add("tool."..gsToolName..".left"          , "Spawn/snap a piece. Hold SHIFT to stack")
  language.Add("tool."..gsToolName..".right"         , "Switch assembly points. Hold SHIFT for versa (Quick: ALT + SCROLL)")
  language.Add("tool."..gsToolName..".right_use"     , "Open frequently used pieces menu"
  language.Add("tool."..gsToolName..".reload"        , "Remove a piece. Hold SHIFT to select an anchor")
  language.Add("tool."..gsToolName..".desc"          , "Assembles a track for vehicles to run on")
  language.Add("tool."..gsToolName..".name"          , "Pipe assembly tool")
  language.Add("tool."..gsToolName..".forcelim"      , "Defines the force limit on the pipe welds")
  language.Add("tool."..gsToolName..".forcelim_con"  , "Force limit")
  language.Add("tool."..gsToolName..".nextpic"       , "Additional origin angular pitch offset")
  language.Add("tool."..gsToolName..".nextpic_con"   , "Pitch offset")
  language.Add("tool."..gsToolName..".nextyaw"       , "Additional origin angular yaw offset")
  language.Add("tool."..gsToolName..".nextyaw_con"   , "Yaw offset")
  language.Add("tool."..gsToolName..".nextrol"       , "Additional origin angular roll offset")
  language.Add("tool."..gsToolName..".nextrol_con"   , "Roll offset")
  language.Add("tool."..gsToolName..".model"         , "Pipeline piece model is selected here")
  language.Add("tool."..gsToolName..".model_con"     , "Model")
  language.Add("tool."..gsToolName..".freeze"        , "Makes the piece spawn in a frozen state")
  language.Add("tool."..gsToolName..".freeze_con"    , "Freeze piece")
  language.Add("tool."..gsToolName..".freeze"        , "Controls the gravity on the piece spawned")
  language.Add("tool."..gsToolName..".freeze_con"    , "Apply piece gravity")
  language.Add("tool."..gsToolName..".nocollide"     , "Creates a no-collide between pieces")
  language.Add("tool."..gsToolName..".nocollide_con" , "No-Collide")
  language.Add("tool."..gsToolName..".weld"          , "Creates a weld constraint between pieces")
  language.Add("tool."..gsToolName..".weld_con"      , "Weld")
  language.Add("tool."..gsToolName..".adviser"       , "Controls rendering the tool position/angle adviser")
  language.Add("tool."..gsToolName..".adviser_con"   , "Draw adviser")
  language.Add("tool."..gsToolName..".pntasist"      , "Controls rendering the tool snap point assistant")
  language.Add("tool."..gsToolName..".pntasist_con"  , "Draw assistant")
  language.Add("tool."..gsToolName..".nophysgun_con" , "Ignore physgun")
  language.Add("tool."..gsToolName..".nophysgun"     , "Ignores physgun iteractions on the pipe")
  language.Add("tool."..gsToolName..".resetvars_con" , "Reset variables")
  language.Add("tool."..gsToolName..".resetvars"     , "Click here to reset pipe offsets")
  language.Add("Cleanup_"..gsLimitName               , "Assembled track pieces")
  language.Add("Cleaned_"..gsLimitName               , "Cleaned up all track pieces")
  language.Add("SBoxLimit_"..gsLimitName             , "You've hit the spawned tracks limit!")

  TOOL.Information = {
    { name = "info",  stage = 1   },
    { name = "left"      },
    { name = "right"     },
    { name = "right_use",icon2 = "gui/e.png" },
    { name = "reload"    }
  }

  concommand.Add(gsToolName_.."resetvars", function(oPly, oCom, oArgs)
    oPly:ConCommand(gsToolName_.."nextpic 0\n")
    oPly:ConCommand(gsToolName_.."nextyaw 0\n")
    oPly:ConCommand(gsToolName_.."nextrol 0\n")
  end)

end

if(SERVER) then
  function newPipe(pPly, sT, sM, vP, aA)
    if(CLIENT) then return nil end
    if(not (pPly and pPly:IsValid() and pPly:IsPlayer())) then return nil end
    if(not pPly:CheckLimit(sLimit)) then return nil end
    if(not pPly:CheckLimit(gsLimitName)) then return nil end

    local stPiece = CacheQueryPiece(sModel) if(not IsHere(stPiece)) then
      LogInstance("Record missing for <"..sModel..">"); return nil end
    local ePiece = entsCreate(GetTerm(stPiece.Unit, sClass, sClass))
    if(not (ePiece and ePiece:IsValid())) then -- Create the piece unit
      LogInstance("Piece invalid <"..tostring(ePiece)..">"); return nil end
    ePiece:SetCollisionGroup(COLLISION_GROUP_NONE)
    ePiece:SetSolid(SOLID_VPHYSICS)
    ePiece:SetMoveType(MOVETYPE_VPHYSICS)
    ePiece:SetNotSolid(false)
    ePiece:SetModel(sModel)
    if(not SetPosBound(ePiece,vPos or GetOpVar("VEC_ZERO"),pPly,sMode)) then
      LogInstance(pPly:Nick().." spawned <"..sModel.."> outside"); return nil end
    ePiece:SetAngles(aAng or GetOpVar("ANG_ZERO"))
    ePiece:Spawn()
    ePiece:Activate()
    ePiece:SetRenderMode(RENDERMODE_TRANSALPHA)
    ePiece:SetColor(clColor or GetColor(255,255,255,255))
    ePiece:DrawShadow(false)
    ePiece:PhysWake()
    local phPiece = ePiece:GetPhysicsObject()
    if(not (phPiece and phPiece:IsValid())) then ePiece:Remove()
      LogInstance("Entity phys object invalid"); return nil end
    phPiece:EnableMotion(false); ePiece.owner = pPly -- Some SPPs actually use this value
    local Mass = (tonumber(nMass) or 1); phPiece:SetMass((Mass >= 1) and Mass or 1)
    local BgSk = GetOpVar("OPSYM_DIRECTORY"):Explode(sBgSkIDs or "")
    ePiece:SetSkin(mathClamp(tonumber(BgSk[2]) or 0,0,ePiece:SkinCount()-1))
    if(not AttachBodyGroups(ePiece,BgSk[1])) then ePiece:Remove()
      LogInstance("Failed attaching bodygroups"); return nil end
    if(not AttachAdditions(ePiece)) then ePiece:Remove()
      LogInstance("Failed attaching additions"); return nil end
    pPly:AddCount(sLimit , ePiece); pPly:AddCleanup(sLimit , ePiece) -- This sets the ownership
    pPly:AddCount("props", ePiece); pPly:AddCleanup("props", ePiece) -- To be deleted with clearing props
    LogInstance("{"..tostring(ePiece).."}"..sModel); return ePiece
  end
end

TOOL.Category   = ("#tool."..gsToolName..".category")
TOOL.Name       = ("#tool."..gsToolName..".name")
TOOL.Command    = nil -- Command on click (nil for default)
TOOL.ConfigName = nil -- Configure file name (nil for default)

TOOL.ClientConVar = {
  ["nextpic"   ] = 0,       -- Angle user deviation pitch
  ["nextyaw"   ] = 0,       -- Angle user deviation yaw
  ["nextrol"   ] = 0,       -- Angle user deviation roll
  ["type"      ] = gsDefaultStr, -- This contains the default type when combo box is not yet triggered
  ["model"     ] = gsDefaultStr, -- Pipe entity model the iser has selected trough the panel
  ["forcelim"  ] = 0,       -- Force limit on for the constraints linking pipes ( if available )
  ["radius"    ] = 0,       -- Radius if bigger than zero circular collision is used
  ["nocollide" ] = 0,       -- Enabled creates a no-collision constraint between it and the trace
  ["weld"      ] = 0,       -- Enabled creates a weld constraint between it and the trace
  ["nophysgun" ] = 0,       -- Enabled ignores the physgun iteraction with the player beam ( persistemt )
  ["pointid"   ] = 1,       -- The current active end selected by the user
  ["pnextid"   ] = 2,       -- The next active end selected by the user
}

function TOOL:GetUserAngles()
  return math.Clamp(self:GetClientNumber("nextpic", 0), -gnMaxRotate, gnMaxRotate),
         math.Clamp(self:GetClientNumber("nextyaw", 0), -gnMaxRotate, gnMaxRotate),
         math.Clamp(self:GetClientNumber("nextrol", 0), -gnMaxRotate, gnMaxRotate)
end

function TOOL:GetPointID()
  return math.Clamp(self:GetClientNumber("pointid", 0), 0, math.huge),
         math.Clamp(self:GetClientNumber("pnextid", 0), 0, math.huge),
end

function TOOL:GetAdviser()
  tobool(self:GetClientNumber("adviser", 0))
end

function TOOL:GetAssist()
  tobool(self:GetClientNumber("pntasist", 0))
end

function TOOL:GetFreeze()
  tobool(self:GetClientNumber("freeze", 0))
end

function TOOL:GetGravity()
  tobool(self:GetClientNumber("gravity", 0))
end

function TOOL:GetModel()
  return tostring(self:GetClientInfo("model") or "")
end

function TOOL:GetForceLimit()
  return math.Clamp(self:GetClientNumber("forcelim", 0), 0, gnMaxForceLim),
end

function TOOL:GetRadius()
  return math.Clamp(self:GetClientNumber("radius", 0), 0, gnMaxRadius)
end

function TOOL:GetWeld()
  return tobool(self:GetClientNumber("weld", 0))
end

function TOOL:GetNoCollide()
  return tobool(self:GetClientNumber("nocollide", 0))
end

function TOOL:GetNoPhysgun()
  return tobool(self:GetClientNumber("ignphysgun", 0))
end

function TOOL:LeftClick(tr)
  if(CLIENT) then return end
end

function TOOL:RightClick(tr)
  if(CLIENT) then return end
end

function TOOL:Reload(tr)
  if(CLIENT) then return end
end

function TOOL:Holster(tr)
end

function TOOL:DrawHUD(tr)
  if(SERVER) then return end
end

function TOOL:Think(tr)
end

local gtConvarList = TOOL:BuildConVarList()
function TOOL.BuildCPanel(cPanel)
  cPanel:ClearControls()
  local CurY, pItem = 0 -- pItem is the current panel created
          cPanel:SetName("#tool."..gsToolName..".name")
  pItem = cPanel:Help   ("#tool."..gsToolName..".desc")
  CurY  = CurY + pItem:GetTall() + 2

  local pComboPresets = vguiCreate("ControlPresets", cPanel)
        pComboPresets:SetPreset(gsToolName)
        pComboPresets:AddOption("default", gtConvarList)
        for key, val in pairs(tableGetKeys(gtConvarList)) do
          pComboPresets:AddConVar(val) end
  cPanel:AddItem(pComboPresets); CurY = CurY + pItem:GetTall() + 2

  local pTree = vguiCreate("DTree", cPanel)
        pTree:SetPos(2, CurY)
        pTree:SetSize(2, 400)
        pTree:SetTooltip("#tool."..gsToolNameL..".model")
        pTree:SetIndentSize(0)
  local tTyp, iD = pipeGetKeySort(gtDataBase), 1
  while(tTyp[iD]) do local sTyp = tTyp[iD]
    local pRoot = pTree:AddNode(sTyp)
          pRoot.Icon:SetImage("icon16/database_connect.png")
          pRoot.InternalDoClick = function() end
          pRoot.DoClick         = function() return false end
          pRoot.DoRightClick    = function() SetClipboardText(pRoot:GetText()) end
          pRoot.Label.UpdateColours = function(pSelf)
            return pSelf:SetTextStyleColor(gtColorBase["tx"]) end
    local tSort, iМ = pipeGetKeySort(gtDataBase[sTyp]), 1
    while(tSort[iM]) do local sMod = tSort[iM]
      local sNam = sMod:GetFileFromFilename():gsub("%.mdl", "")
      pNode = pRoot:AddNode(sNam)
      pNode.DoRightClick = function() SetClipboardText(sMod) end
      pNode:SetTooltip("#tool."..gsToolNameL..".model_con")
      pNode.Icon:SetImage("icon16/dbrick.png")
      pNode.DoClick = function(pSelf)
        RunConsoleCommand(gsToolName_.."model"  , sMod)
        RunConsoleCommand(gsToolName_.."type"   , sTyp)
        RunConsoleCommand(gsToolName_.."pointid", 1)
        RunConsoleCommand(gsToolName_.."pnextid", 2)
      end
      iM = (iM + 1)
    end
    iD = (iD + 1)
  end

  pItem = cPanel:Button    ("#tool."..gsToolName_..".resetvars_con", gsToolName_.."resetvars")
           pItem:SetTooltip("#tool."..gsToolName_..".resetvars")
  pItem = cPanel:CheckBox  ("#tool."..gsToolName_..".gravity_con", gsToolPrefL.."gravity")
           pItem:SetTooltip("#tool."..gsToolName_..".gravity")
  pItem = cPanel:CheckBox  ("#tool."..gsToolName_..".freeze_con", gsToolPrefL.."freeze")
           pItem:SetTooltip("#tool."..gsToolName_..".freeze")
  pItem = cPanel:CheckBox  ("#tool."..gsToolName_..".weld_con", gsToolPrefL.."weld")
           pItem:SetTooltip("#tool."..gsToolName_..".weld")
  pItem = cPanel:CheckBox  ("#tool."..gsToolName_..".nocollide_con", gsToolPrefL.."nocollide")
           pItem:SetTooltip("#tool."..gsToolName_..".nocollide")
  pItem = cPanel:CheckBox  ("#tool."..gsToolNameL..".adviser_con", gsToolPrefL.."adviser")
           pItem:SetTooltip("#tool."..gsToolNameL..".adviser")
  pItem = cPanel:CheckBox  ("#tool."..gsToolNameL..".pntasist_con", gsToolPrefL.."pntasist")
           pItem:SetTooltip("#tool."..gsToolNameL..".pntasist")

end
