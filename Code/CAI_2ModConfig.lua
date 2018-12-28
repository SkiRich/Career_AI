-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018


local lf_print = false -- Setup debug printing in local file

local StringIdBase = 17764701500 -- Career AI  : 701500 - 701599 this file: 1-49 Next: 6

local steam_id = "0"
local mod_name = "Career A.I"
local ModDir = CurrentModPath
local iconCIAnotice = ModDir.."UI/Icons/CareerAINotice.png"

-- Variable replacement for mod config steam id for check.
local ModConfig_id = "1542863522" -- Reborn
local ModConfigWaitThread = false
g_ModConfigLoaded = false

function OnMsg.ModConfigReady()

    -- Register this mod's name and description
    ModConfig:RegisterMod("CAI", -- ID
        T{StringIdBase, "Career A.I."}, -- Optional display name, defaults to ID
        T{StringIdBase + 1, "Options for Automated Tradepad"} -- Optional description
    )

    ModConfig:RegisterOption("CAI", "CAIenabled", {
        name = T{StringIdBase + 2, "Enable Career A.I.: "},
        desc = T{StringIdBase + 3, "Enable Career A.I. or Disable and use in game workplace A.I"},
        type = "boolean",
        default = true,
        order = 1
    })

end -- ModConfigReady

function OnMsg.ModConfigChanged(mod_id, option_id, value, old_value, token)
  if g_ModConfigLoaded and (mod_id == "CAI") and (token ~= "reset") then

  	-- g_CAIenabled
  	if option_id == "CAIenabled" then
  		g_CAIenabled = value

	    local msgCIA = ""
	    if g_CAIenabled then
	    	msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	    else
	    	msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	    end -- if g_CAIenabled
	    AddCustomOnScreenNotification("CIA_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CIAnoticeDismissTime})
	    PlayFX("UINotificationResearchComplete")
  	end -- if option_id

  end -- if g_ModConfigLoaded
end -- OnMsg.ModConfigChanged


function OnMsg.CityStart()
	-- load up defaults
	if g_ModConfigLoaded then
		local CAIenabled = ModConfig:Get("CIA", "CAIenabled")
		if g_CAIenabled ~= CAIenabled then ModConfig:Set("CIA", "CAIenabled", g_CAIenabled, "reset") end
	end -- if g_ModConfigLoaded
end -- OnMsg.CityStart()

function OnMsg.NewMapLoaded()
	local msgCIA = ""
	if g_CAIenabled then
		msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	else
		msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	end -- if g_CAIenabled
	AddCustomOnScreenNotification("CIA_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CIAnoticeDismissTime})
	PlayFX("UINotificationResearchComplete")
end -- OnMsg.NewMapLoaded()


function OnMsg.LoadGame()
	-- load up defaults
	if g_ModConfigLoaded then
		local CAIenabled = ModConfig:Get("CIA", "CAIenabled")
		if g_CAIenabled ~= CAIenabled then ModConfig:Set("CIA", "CAIenabled", g_CAIenabled, "reset") end
	end -- if g_ModConfigLoaded

	local msgCIA = ""
	if g_CAIenabled then
		msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	else
		msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	end -- if g_CAIenabled
	AddCustomOnScreenNotification("CIA_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CIAnoticeDismissTime})
	PlayFX("UINotificationResearchComplete")
end -- OnMsg.LoadGame()