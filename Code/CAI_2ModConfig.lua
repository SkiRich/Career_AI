-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018
-- Updated March 24th, 2021

local lf_print = false -- Setup debug printing in local file

local StringIdBase = 17764701500 -- Career AI  : 701500 - 701599 this file: 1-49 Next: 7
-- using 17764701506 in items.lua

local steam_id = "1606337956"
local mod_name = "Career A.I"
local ModDir = CurrentModPath
local iconCIAnotice = ModDir.."UI/Icons/CareerAINotice.png"

-- Variable replacement for mod config steam id for check.
local ModConfig_id = "1542863522" -- Reborn
local ModConfigWaitThread = false
g_ModConfigLoaded = false
---------------------------------------------------------------------------------------------

-- fired when settings are changed/init
local function ModOptions()
	g_CAIenabled = CurrentModOptions:GetProperty("EnableMod")
	ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset")
end -- function ModOptions()

-- load default/saved settings
OnMsg.ModsReloaded = ModOptions

-- fired when Mod Options>Apply button is clicked
function OnMsg.ApplyModOptions(id)
	if id == CurrentModId then
		ModOptions()
	end
end -- OnMsg.ApplyModOptions(id)



---------------------------------------------------------------------------------------------
function OnMsg.ModConfigReady()

    -- Register this mod's name and description
    ModConfig:RegisterMod("CAI", -- ID
        T{StringIdBase, "Career A.I."}, -- Optional display name, defaults to ID
        T{StringIdBase + 1, "Options for Career A.I."} -- Optional description
    )

    -- g_CAIenabled
    ModConfig:RegisterOption("CAI", "CAIenabled", {
        name = T{StringIdBase + 2, "Enable Career A.I.: "},
        desc = T{StringIdBase + 3, "Enable Career A.I. or Disable and use in game workplace A.I"},
        type = "boolean",
        default = true,
        order = 1
    })

    -- g_CAIminSpecialists
    ModConfig:RegisterOption("CAI", "CAIminSpecialists", {
        name = T{StringIdBase + 6, "Auto dismiss notification time in seconds:"},
        desc = T{StringIdBase + 7, "The number of seconds to keep notifications on screen before dismissing."},
        type = "number",
        default = 20,
        min = 1,
        max = 200,
        step = 1,
        order = 2
    })

end -- ModConfigReady

function OnMsg.ModConfigChanged(mod_id, option_id, value, old_value, token)
  if g_ModConfigLoaded and (mod_id == "CAI") and (token ~= "reset") then

  	-- g_CAIenabled
  	if option_id == "CAIenabled" then
  		g_CAIenabled = value
  		-- add in Mod Options
  		CurrentModOptions:SetProperty("EnableMod", value)

  		CAIincompatibeModCheck()

	    local msgCIA = ""
	    if g_CAIenabled and (not g_CAIoverride) then
	    	msgCIA = T(StringIdBase + 4, "Career A.I. is enabled")
	    else
	    	msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
	    end -- if g_CAIenabled
	    AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	    PlayFX("UINotificationResearchComplete")
  	end -- if g_CAIenabled

    -- g_CAIminSpecialists
    if option_id == "CAIminSpecialists" then
    	g_CAIminSpecialists = value
    end -- if g_CAIminSpecialists

  end -- if g_ModConfigLoaded
end -- OnMsg.ModConfigChanged


function OnMsg.CityStart()
	-- load up defaults
	if g_ModConfigLoaded then
		local CAIenabled = ModConfig:Get("CAI", "CAIenabled")
		if g_CAIenabled ~= CAIenabled then
			ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset")
			CurrentModOptions:SetProperty("EnableMod", true) -- Mod Option
		end -- if g_CAIenabled
		-- Mod Options not needed here since default is true

		local CAIminSpecialists = ModConfig:Get("CAI", "CAIminSpecialists")

	end -- if g_ModConfigLoaded

  -- if playing Amateurs rule make sure we check to suspend CAI
	CAIcheckAmateurs(true)

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
	CAIcheckAmateurs(false)
	-- load up defaults
	if g_ModConfigLoaded then
		local CAIenabled = ModConfig:Get("CAI", "CAIenabled")
		if g_CAIenabled ~= CAIenabled then
			ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset")
			CurrentModOptions:SetProperty("EnableMod", g_CAIenabled) -- Mod Option
		end -- if g_CAIenabled ~= CAIenabled
	else
		-- if they dont use mod config reborn
		CurrentModOptions:SetProperty("EnableMod", g_CAIenabled) -- Mod Option
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

function OnMsg.NewDay(day)
	CAIcheckAmateurs(false)
end -- OnMsg.NewDay()


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