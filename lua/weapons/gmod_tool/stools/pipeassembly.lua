gsToolName =

if(CLIENT) then
  language.Add("tool."..gsToolName..".category" , "Construction")

  TOOL.Information = {
    { name = "info",  stage = 1   },
    { name = "left"         },
    { name = "right"        },
    { name = "reload"       }
  }

  concommand.Add(gsToolNameU.."resetoffs", function(oPly,oCom,oArgs)
    oPly:ConCommand(gsToolNameU.."linx 0\n")
    oPly:ConCommand(gsToolNameU.."liny 0\n")
    oPly:ConCommand(gsToolNameU.."linz 0\n")
    oPly:ConCommand(gsToolNameU.."angp 0\n")
    oPly:ConCommand(gsToolNameU.."angy 0\n")
    oPly:ConCommand(gsToolNameU.."angr 0\n")
  end)
end

TOOL.Category   = language and language.GetPhrase("tool."..gsToolName..".category")
TOOL.Name       = language and language.GetPhrase("tool."..gsToolName..".name")
TOOL.Command    = nil -- Command on click (nil for default)
TOOL.ConfigName = nil -- Configure file name (nil for default)

TOOL.ClientConVar = {
  ["mass"      ] = 300,     -- Pipe entity mass when created
  ["linx"      ] = 0,       -- Linear user deviation X
  ["liny"      ] = 0,       -- Linear user deviation Y
  ["linz"      ] = 0,       -- Linear user deviation Z
  ["angp"      ] = 0,       -- Angle user deviation pitch
  ["angy"      ] = 0,       -- Angle user deviation yaw
  ["angr"      ] = 0,       -- Angle user deviation roll
  ["model"     ] = "models/props_trainstation/trainstation_clock001.mdl", -- Pipe entity model
  ["forcelim"  ] = 0,       -- Force limit on for the constraints linking spinner to trace ( if available )
  ["radius"    ] = 0,       -- Radius if bigger than zero circular collision is used
  ["nocollide" ] = 0,       -- Enabled creates a no-collision constraint between it and the trace
  ["weld"      ] = 0,       -- Enabled creates a weld constraint between it and the trace
  ["ignphysgun"] = 0,       -- Enabled ignores the physgun iteraction with the player beam ( persistemt )
}