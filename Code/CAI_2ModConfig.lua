-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018
-- Updated March 24th, 2021

local lf_print = false -- Setup debug printing in local file

local StringIdBase = 17764701500 -- Career AI  : 701500 - 701599 this file: 1-49 Next: 13
-- using 17764701506 in items.lua

local steam_id = "1606337956"
local mod_name = "Career A.I"
local ModDir = CurrentModPath
local iconCIAnotice = ModDir.."UI/Icons/CareerAINotice.png"

-- Variable replacement for mod config steam id for check.
local ModConfig_id = "1542863522" -- Reborn
local ModConfigWaitThread = false
local TableFind  = table.find
local ModConfigLoaded = TableFind(ModsLoaded, "steam_id", ModConfig_id) or false

---------------------------------------------------------------------------------------------

-- wait for mod config to load or fail out and use defaults
local function WaitForModConfig()
  if (not ModConfigWaitThread) or (not IsValidThread(ModConfigWaitThread)) then
    ModConfigWaitThread = CreateRealTimeThread(function()
      if lf_print then print(string.format("%s WaitForModConfig Thread Started", mod_name)) end
      local tick = 240  -- (60 seconds) loops to wait before fail and exit thread loop
      while tick > 0 do
        if ModConfigLoaded and ModConfig:IsReady() then
          -- if ModConfig loaded and is in ready state then break out of loop
          if lf_print then print(string.format("%s Found Mod Config", mod_name)) end
          tick = 0
          break
        else
          tick = tick -1
          Sleep(250) -- Sleep 1/4 second
          ModConfigLoaded = TableFind(ModsLoaded, "steam_id", ModConfig_id) or false
        end -- if ModConfigLoaded
      end -- while
      if lf_print then print(string.format("%s WaitForModConfig Thread Continuing", mod_name)) end

      -- See if ModConfig is installed and any defaults changed
      if ModConfigLoaded and ModConfig:IsReady() then
	      -- load up defaults
	      -- these are all persistent vars so vars take presedence over modconfig
		    local CAIenabled = ModConfig:Get("CAI", "CAIenabled")
		    if g_CAIenabled ~= CAIenabled then
			    ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset")
			    CurrentModOptions:SetProperty("EnableMod", g_CAIenabled) -- Mod Option
		    end -- if g_CAIenabled
		    -- Mod Options not needed here since default is true

		    local CAIminSpecialists = ModConfig:Get("CAI", "CAIminSpecialists")
		    if g_CAIminSpecialists ~= CAIminSpecialists then
          ModConfig:Set("CAI", "CAIminSpecialists", g_CAIminSpecialists, "reset")
        end -- if g_CAIminSpecialists

        -- g_CAInoticeDismissTime = 15000
		    local CAInoticeDismissTime = ModConfig:Get("CAI", "CAInoticeDismissTime")
		    if g_CAInoticeDismissTime ~= (CAInoticeDismissTime * 1000) then
          ModConfig:Set("CAI", "CAInoticeDismissTime", MulDivRound(g_CAInoticeDismissTime, 1, 1000), "reset")
        end --   if g_CAInoticeDismissTime


        ModLog(string.format("%s detected ModConfig running - Setup Complete", mod_name))
      else
        -- PUT MOD DEFAULTS HERE OR SET THEM UP BEFORE RUNNING THIS FUNCTION --
        -- CAI defaults are setup in Init File

        if lf_print then print(string.format("**** %s - Mod Config Never Detected On Load - Using Defaults ****", mod_name)) end
        ModLog(string.format("**** %s - Mod Config Never Detected On Load - Using Defaults ****", mod_name))
      end -- end if ModConfigLoaded

      -- put up a message about status
      local msgCIA = ""
	    if g_CAIenabled and (not g_CAIoverride) then
	    	msgCIA = T(StringIdBase + 1, "Career A.I. is enabled")
	    else
	    	msgCIA = T(StringIdBase + 2, "Career A.I. is disabled")
	    end -- if g_CAIenabled
	    AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	    PlayFX("UINotificationResearchComplete")

      if lf_print then print(string.format("%s WaitForModConfig Thread Ended", mod_name)) end
    end) -- thread
  else
    if lf_print then print(string.format("%s Error - WaitForModConfig Thread Never Ran", mod_name)) end
    ModLog(string.format("%s Error - WaitForModConfig Thread Never Ran", mod_name))
  end -- check to make sure thread not running
end -- WaitForModConfig



-- fired when settings are changed/init
local function ModOptions()
	g_CAIenabled = CurrentModOptions:GetProperty("EnableMod")
	if ModConfigLoaded then ModConfig:Set("CAI", "CAIenabled", g_CAIenabled, "reset") end
end -- function ModOptions()

-- load default/saved settings
OnMsg.ModsReloaded = ModOptions

-- fired when Mod Options>Apply button is clicked
function OnMsg.ApplyModOptions(id)
	if id == CurrentModId then
		ModOptions()
	end -- if id
end -- OnMsg.ApplyModOptions(id)

--------------------------------------------------------------------------------------------

-- popup notification when user is playing amateur rules
local function CAIamateurPopup()
    CreateRealTimeThread(function()
        local params = {
            title = T{StringIdBase, "Career A.I."},
             text = "",
            choice1 = T{StringIdBase + 3, "Ok"},
            image = "UI/Messages/hints.tga",
            start_minimized = false,
        } -- params

        local texts = {
        	T(StringIdBase + 4, "<em>Career A.I. settings overridden and it has been turned off.</em>"),
        	T(StringIdBase + 5, "Career A.I. has detected the Game Rule - Amateurs - is active."),
        	T(StringIdBase + 6, "Career A.I. will reactivate when you have the minimum amount of specialists as set in Mod Config Reborn, or the default of 20 if you do not have Mod Config Reborn."),
          T(StringIdBase + 7, "Career A.I. will check once every sol for specialists."),
        }
        params.text = table.concat(texts, "<newline>")
        Sleep(15000) -- add 10 second delay to allow for the map load to prevent issue with lockup
        local choice = WaitPopupNotification(false, params)
    end ) -- CreateRealTimeThread
end -- function end


-- check for the right conditions to start CAI if playing Amateurs
local function CAIcheckAmateurs(gamestart)
	-- short circuit if not playing Amateurs
	if not g_CurrentMissionParams.idGameRules["Amateurs"] then return end

	-- short circuit if we are done checking for this condition in later game
	if not g_CAIamateurCheck then return end

	if lf_printRules then print("**** Running CAIcheckAmateurs() since playing Amateurs ****") end

	-- gather specialists
	local colonists   = UICity.labels.Colonist or empty_table
	local numSpecialists = 0
	for i = 1, #colonists do
		if colonists[i].specialist and colonists[i].specialist ~= "none" then numSpecialists = numSpecialists + 1 end
	end -- for i

	if lf_printRules then print ("Number of specialists: ", numSpecialists) end

	if g_CAIenabled and (numSpecialists <= g_CAIminSpecialists) then
		if lf_printRules then print("**** #### Not enough specialists to enable CAI #### ****") end
		if gamestart then CAIamateurPopup() end
		g_CAIenabled = false
		if ModConfigLoaded then ModConfig:Set("CAI", "CAIenabled", g_CAIenabled) end
		CurrentModOptions:SetProperty("EnableMod", g_CAIenabled)
	elseif (numSpecialists >= g_CAIminSpecialists) then
		if lf_printRules then print("**** #### There is enough specialists - disabling check, enabling CAI #### ****") end
    g_CAIamateurCheck = false
    g_CAIenabled = true
    if ModConfigLoaded then ModConfig:Set("CAI", "CAIenabled", g_CAIenabled) end
    CurrentModOptions:SetProperty("EnableMod", g_CAIenabled)
	end -- if numSpecialists

end -- CAIcheckAmateurs()


---------------------------------------------------------------------------------------------
function OnMsg.ModConfigReady()

    -- Register this mod's name and description
    ModConfig:RegisterMod("CAI", -- ID
        T{StringIdBase, "Career A.I."}, -- Optional display name, defaults to ID
        T{StringIdBase + 8, "Options for Career A.I."} -- Optional description
    )

    -- g_CAIenabled
    ModConfig:RegisterOption("CAI", "CAIenabled", {
        name = T{StringIdBase + 9, "Enable Career A.I.: "},
        desc = T{StringIdBase + 10, "Enable Career A.I. or Disable and use in game workplace A.I"},
        type = "boolean",
        default = true,
        order = 1
    })

    -- g_CAIminSpecialists
    ModConfig:RegisterOption("CAI", "CAIminSpecialists", {
        name = T{StringIdBase + 11, "Minimum number of specialists:"},
        desc = T{StringIdBase + 12, "The minimum number of specialists to have when playing amateur rule."},
        type = "number",
        default = 20,
        min = 1,
        max = 200,
        step = 1,
        order = 2
    })

    -- g_CAInoticeDismissTime = 15000  -- var to time the notification dismissal 15 seconds
    ModConfig:RegisterOption("CAI", "CAInoticeDismissTime", {
        name = T{StringIdBase + 13, "Auto dismiss notification time in seconds:"},
        desc = T{StringIdBase + 14, "The number of seconds to keep notifications on screen before dismissing."},
        type = "number",
        default = 15,
        min = 1,
        max = 60,
        step = 1,
        order = 3
    })


end -- ModConfigReady

function OnMsg.ModConfigChanged(mod_id, option_id, value, old_value, token)
  if ModConfigLoaded and (mod_id == "CAI") and (token ~= "reset") then

  	-- g_CAIenabled
  	if option_id == "CAIenabled" then
  		g_CAIenabled = value
  		-- add in Mod Options
  		CurrentModOptions:SetProperty("EnableMod", value)

  		CAIincompatibeModCheck()

	    local msgCIA = ""
	    if g_CAIenabled and (not g_CAIoverride) then
	    	msgCIA = T(StringIdBase + 1, "Career A.I. is enabled")
	    else
	    	msgCIA = T(StringIdBase + 2, "Career A.I. is disabled")
	    end -- if g_CAIenabled
	    AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	    PlayFX("UINotificationResearchComplete")
  	end -- if g_CAIenabled

    -- g_CAIminSpecialists
    if option_id == "CAIminSpecialists" then
    	g_CAIminSpecialists = value
    end -- if g_CAIminSpecialists

    -- g_CAInoticeDismissTime = 15000
    if option_id == "CAInoticeDismissTime" then
    	g_CAInoticeDismissTime = value * 1000
    end -- if g_CAInoticeDismissTime

  end -- if ModConfigLoaded
end -- OnMsg.ModConfigChanged


function OnMsg.CityStart()
  WaitForModConfig()
	CAIcheckAmateurs(true)
	CAIincompatibeModCheck()
end -- OnMsg.CityStart()


function OnMsg.LoadGame()
  WaitForModConfig()
	CAIincompatibeModCheck()
	CAIcheckAmateurs(false)
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