-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018
-- Updated June 4th, 2019

local lf_print = false -- Setup debug printing in local file

local StringIdBase = 17764701500 -- Career AI  : 701500 - 701599 this file: 1-49 Next: 6

local steam_id = "1606337956"
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
        T{StringIdBase + 1, "Options for Career A.I."} -- Optional description
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

  		CAIincompatibeModCheck()

	    local msgCIA = ""
	    if g_CAIenabled and (not g_CAIoverride) then
	    	msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	    else
	    	msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	    end -- if g_CAIenabled
	    AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	    PlayFX("UINotificationResearchComplete")
  	end -- if option_id

  end -- if g_ModConfigLoaded
end -- OnMsg.ModConfigChanged


function OnMsg.CityStart()
	-- load up defaults
	if g_ModConfigLoaded then
		local CAIenabled = ModConfig:Get("CAI", "CAIenabled")
		if g_CAIenabled ~= CAIenabled then ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset") end
	end -- if g_ModConfigLoaded
end -- OnMsg.CityStart()

function OnMsg.NewMapLoaded()
	CAIincompatibeModCheck()
	local msgCIA = ""
	if g_CAIenabled and (not g_CAIoverride) then
		msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	else
		msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	end -- if g_CAIenabled
	AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	PlayFX("UINotificationResearchComplete")
end -- OnMsg.NewMapLoaded()


function OnMsg.LoadGame()
	CAIincompatibeModCheck()
	-- load up defaults
	if g_ModConfigLoaded then
		local CAIenabled = ModConfig:Get("CAI", "CAIenabled")
		if g_CAIenabled ~= CAIenabled then ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset") end
	end -- if g_ModConfigLoaded

	local msgCIA = ""
	if g_CAIenabled and (not g_CAIoverride) then
		msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	else
		msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	end -- if g_CAIenabled
	AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	PlayFX("UINotificationResearchComplete")
end -- OnMsg.LoadGame()


local function SRDailyPopup()
    CreateRealTimeThread(function()
        local params = {
              title = "Non-Author Mod Copy",
               text = "We have detected an illegal copy version of : ".. mod_name .. ". Please uninstall the existing version.",
            choice1 = "Download the Original [Opens in new window]",
            choice2 = "Damn you copycats!",
            choice3 = "I don't care...",
              image = "UI/Messages/death.tga",
              start_minimized = false,
        } -- params
        local choice = WaitPopupNotification(false, params)
        if choice == 1 then
        	OpenUrl("https://steamcommunity.com/sharedfiles/filedetails/?id=" .. steam_id, true)
        end -- if statement
    end ) -- CreateRealTimeThread
end -- function end


function OnMsg.NewDay(day)
  if table.find(ModsLoaded, "steam_id", steam_id)~= nil then
    --nothing
  else
    SRDailyPopup()
  end -- SRDailyPopup
end --OnMsg.NewDay(day)