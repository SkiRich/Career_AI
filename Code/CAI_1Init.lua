-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018


local lf_print      = false -- Setup debug printing in local file
local lf_printDebug = false -- debug ChooseWorkplace
                            -- Use if lf_print then print("something") end
                            -- use Msg("ToggleLFPrint", "CIA", "printdebug") to toggle

local ModDir = CurrentModPath
local iconCIAnotice = ModDir.."UI/Icons/CareerAINotice.png"
local StringIdBase = 17764701500 -- Career AI  : 701500 - 701599 this file: 50-99 Next: 50

local incompatibleMods = {
	{name = "Smarter Migration AI", id = "1343552210"},
	{name = "Smarter Worker AI",    id = "1338867491"},
	{name = "Better AI",            id = "1361377883"},
	--{name = "Mod Config Reborn",    id = "1542863522"}, -- for testing -- remove before upload
} -- incompatibleMods

GlobalVar("g_CAIenabled", true) -- var to turn on or off CAI
g_CAIoverride = false -- var to override CAI if incompatible mods detected
g_CAInoticeDismissTime = 15000

local IT = _InternalTranslate

-- gather all the open jobs that want specialists
local function CAIgatherOpenJobs()
	local openjobs = {counts = {}, employers = {}}
	local jobsbyspec = {}
	local workplaces = UICity.labels.Workplace or empty_table

	for i = 1, #workplaces do
		if workplaces[i].specialist then -- check to make sure it not nil first (mostly for poorly coded mods)
		  if not jobsbyspec[workplaces[i].specialist] then jobsbyspec[workplaces[i].specialist] = {} end -- setup sub-table
		  table.insert(jobsbyspec[workplaces[i].specialist], workplaces[i])
	  end -- if workplaces[i].specialist
	end -- for i

	for jobspec, workplace in pairs(jobsbyspec) do
		if jobspec ~= "none" then
			if not openjobs.employers[jobspec] then openjobs.employers[jobspec] = {} end -- setup sub-table
			if not openjobs.counts[jobspec] then openjobs.counts[jobspec] = 0 end -- setup sub-table
			for i = 1, #workplace do
				local numopenjobs = 0
				if ValidateBuilding(workplace[i]) then -- check to make sure building is not destroyed
				  numopenjobs = numopenjobs + workplace[i]:GetFreeWorkSlots(1)
				  numopenjobs = numopenjobs + workplace[i]:GetFreeWorkSlots(2)
				  numopenjobs = numopenjobs + workplace[i]:GetFreeWorkSlots(3)
				end -- if ValidateBuilding
				if numopenjobs > 0 then
					table.insert(openjobs.employers[jobspec], workplace[i])
					openjobs.counts[jobspec] = openjobs.counts[jobspec] + numopenjobs
				end -- if numopenjobs > 0
			end -- for i
		end -- if jobspec
	end -- for each jobspec

	--ex(jobsbyspec, nil, "Jobs By Spec")
	--ex(openjobs, nil, "Jobs with Open Slots")

  return openjobs
end -- CAIgatherOpenJobs()


-- gather colonists with specialities working non-specialty jobs
-- exclude colonists at sanatorium and university (shouldn't have specialists in university anyway)
-- exclude children and seniors that cannot work
local function CAIgatherColonists()
	local colonists = UICity.labels.Colonist or empty_table
	local jobhunters = {}

	for i = 1, #colonists do
		local c = colonists[i]
		if c.specialist and c.specialist ~= "none" and c:_IsWorkStatusOk() and
		   (not IsKindOf(c.workplace, "Sanatorium")) and
		   (not IsKindOf(c.workplace, "MartianUniversity")) and
		   ((not c.workplace) or (c.workplace and c.workplace.specialist ~= c.specialist)) then
			-- colonist is a specialist
			-- colonist can work see Colonist:_IsWorkStatusOk()
			-- is not in a sanatorium or MU
			-- jobless gets priority then specialists working in the wrong specialty
			if not jobhunters[c.specialist] then jobhunters[c.specialist] = {} end -- create sub-table
			table.insert(jobhunters[c.specialist], c)
		end
	end -- for i

	--ex(jobhunters)
	return jobhunters
end -- CAIgatherColonists()


local function CAIgetFreeSlots(workplace)
	local numopenslots = {}
	if ValidateBuilding(workplace) then -- check to make sure building is not destroyed
	  numopenslots[1] = workplace:GetFreeWorkSlots(1)
	  numopenslots[2] = workplace:GetFreeWorkSlots(2)
	  numopenslots[3] = workplace:GetFreeWorkSlots(3)
	end -- if ValidateBuilding
	return numopenslots
end -- CAIgetFreeSlots(employer)


-- main function called once daily to move specialists around to better jobs
function CAIjobhunt(jobtype)
	local openjobs = CAIgatherOpenJobs()
	local jobhunters = CAIgatherColonists()
	local totalopenjobs = 0
	local speclist = jobtype and {jobtype} or ColonistSpecializationList or empty_table

	-- short circuit if no open jobs
	for _, count in pairs(openjobs.counts) do
		totalopenjobs = totalopenjobs + count
	end -- for each count
	if totalopenjobs < 1 then
		if lf_print then print("No Open Jobs") end
		return
	else
		if lf_print then print("Total Open Jobs: ", totalopenjobs) end
	end -- if totalopenjobs

	for spec = 1, #speclist do
		local applicants = jobhunters[speclist[spec]]
		local employers = openjobs.employers[speclist[spec]]
		if applicants and #applicants > 0 and employers and #employers > 0 then
			if lf_print then
				print("--------------------------------------------")
				print("We have applicants and jobs to switch for job type: ", speclist[spec], " - #Applicants: ", #applicants, " #Employers: ", #employers)
			end -- if lf_print
			for i = 1, #employers do
				local numopenslots = CAIgetFreeSlots(employers[i])
				for shift = 1, 3 do
					if numopenslots[shift] > 0 and #applicants > 0 then
						if lf_print then
							print("--------------------------------------------")
							print(string.format("Employer: %s has %s open slots in shift %s", IT(employers[i].name ~= "" and employers[i].name or employers[i].display_name), numopenslots[shift], shift))
						end -- if lf_print
						for slot = 1, numopenslots[shift] do
						  if #applicants > 0 then
						  	if lf_print then
						  		local aworkplace = applicants[1].workplace or "Unemployed"
						  		if aworkplace ~= "Unemployed" then aworkplace = aworkplace.name ~= "" and aworkplace.name or aworkplace.display_name end
						  		print(string.format("Applicant %s is moving from %s to %s", IT(applicants[1].name), IT(aworkplace), IT(employers[i].name ~= "" and employers[i].name or employers[i].display_name)))
						  	end -- if lf_print
						  	if applicants[1]:CanReachBuilding(employers[i]) then -- if they can walk or get a ride then move
						  	  local a_dome = applicants[1].dome or applicants[1].current_dome or applicants[1]:GetPos() -- current_dome is just in case the colonist is currently moving domes.
						  	  local e_dome = employers[i].parent_dome
						  	  if applicants[1].workplace then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  if a_dome == e_dome or IsInWalkingDistDome(a_dome, e_dome) then
						  	  	-- if applicant can get to the job, then set it right away
						  	  	applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	    if a_dome ~= e_dome and e_dome:GetFreeLivingSpace() > 0 then applicants[1]:SetForcedDome(e_dome) end -- relocate colonist if there is space
						  	  elseif a_dome ~= e_dome and IsTransportAvailableBetween(a_dome, e_dome) then
						  	  	-- relocate colonist regardless of space if they can get there via shuttle
						  	  	applicants[1]:SetWorkplace(employers[i], shift)
						  	  	applicants[1]:SetForcedDome(e_dome)
						  	  end --  if IsInWalkingDist
						  	  --employers[i]:ColonistInteract(applicants[1])
						  	  --applicants[1]:UpdateWorkplace()
						  	  --applicants[1]:SetForcedDome(employers[i].parent_dome)
						  	  table.remove(applicants, 1)
						  	else
						  		if lf_print then print("Applicant cant reach prospective employer") end
						  	end -- if can reach
						  else
						  	if lf_print then print("No more applicants available for employer: ", IT(employers[i].name ~= "" and employers[i].name or employers[i].display_name)) end
						  end -- if #applicants > 0
					  end -- for slot
					end -- if numopenslots[shift] > 0
				end -- for shift
			end -- for i
    else
    	if lf_print then print("No match for applicants and employers in:", speclist[spec]) end
		end -- applicant and employers
	end -- for

end -- CAIjobhunt()


-- re-write original function from workplace.lua
-- force specialist to only see specialist work if available
local Old_ChooseWorkplace = ChooseWorkplace
function ChooseWorkplace(unit, workplaces, allow_exchange)
	-- short circuit if disabled
	if (not g_CAIenabled) or g_CAIoverride then
		return Old_ChooseWorkplace(unit, workplaces, allow_exchange)
  end -- if disabled

  -- short circuit for colonists working at Sanatoriums and University's
  if IsKindOfClasses(unit.workplace, "Sanatorium", "MartianUniversity") then
  	if lf_print then print(string.format("***** Colonists %s is at a Sanatorium or MU *****", IT(unit.name))) end
  	return Old_ChooseWorkplace(unit, workplaces, allow_exchange)
  end -- if in Sanatorium

  local sworkplaces = {}
  local specialist = unit.specialist or "" -- dont use none here since we dont want none type workplaces for specialists

  for i = 1, #workplaces do
  	if workplaces[i].specialist and workplaces[i].specialist == specialist then sworkplaces[#sworkplaces+1] = workplaces[i] end
  end -- for i

  if lf_printDebug then
  	print("---------- ChooseWorkplace ------------")
  	print("Specialist: ", specialist)
  	print("Eligible workplaces: ", #sworkplaces)
  end -- if lf_printDebug

  if #sworkplaces > 0 then
  	local best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, sworkplaces, true) -- true here to kick out non specs

    if best_bld and best_shift then
    	-- if we got specialist work, then return that work
  	  if lf_printDebug then
  		  print("Best Bld: ", (best_bld and IT(best_bld.name ~= "" and best_bld.name or best_bld.display_name)))
  		  print("Best Shift: ", best_shift)
  		  print(string.format("Best Kick: %s - %s", (best_to_kick and IT(best_to_kick.name) or ""), (best_to_kick and best_to_kick.specialist or "")  ))
  		  print("Best Spec Match: ", best_specialist_match)
  		  print("--------------------------------------")
  	  end -- if lf_printDebug

  	  -- prevent recently kicked out workers from coming back and kicking someone else out until expiry time.
  	  -- this will prevent rapidly flipping jobs
  	  if best_to_kick then best_to_kick:SetWorkplace(false) end

  	  -- return vars
  	  return best_bld, best_shift, best_to_kick, best_specialist_match
    end -- if best_bld
  end -- if there are specialist workplaces for the colonist

  -- use old function as default
  if lf_printDebug then print("-+= Default ChooseWorkplace in Effect =+-") end
  return Old_ChooseWorkplace(unit, workplaces, allow_exchange)
end -- ChooseWorkplace(unit, workplaces, allow_exchange)

-- incompatible mod check
function CAIincompatibeModCheck()
	local foundIncompatibleMods = {}
	for i = 1, #incompatibleMods do
		if table.find(ModsLoaded, "steam_id", incompatibleMods[i].id) then foundIncompatibleMods[#foundIncompatibleMods+1] = incompatibleMods[i].name end
	end -- for i

	if #foundIncompatibleMods > 0 then
		g_CAIoverride = true -- set override
    CreateRealTimeThread(function()
        local params = {
              title = T(StringIdBase + 50, "Career A.I. Incompatible Mods Check"),
               text = "",
            choice1 = T(StringIdBase + 51, "OK"),
              image = "UI/Messages/hints.tga",
              start_minimized = false,
        } -- params
        local texts = {
        	T(StringIdBase + 52, "<em>Career A.I. settings overridden and it has been turned off.</em>"),
        	T(StringIdBase + 53, "Career A.I. will not function as long as these mods are enabled."),
        	T(StringIdBase + 54, "The following incompatible mods have been detected:<newline>"),
        }
        for i = 1, #foundIncompatibleMods do
        	texts[#texts+1] = foundIncompatibleMods[i]
        end -- for i
        params.text = table.concat(texts, "<newline>")
        local choice = WaitPopupNotification(false, params)
        if choice == 1 then
        end -- if statement
        local msgCIA = T(StringIdBase + 5, "Career A.I. is disabled")
        AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime})
	      PlayFX("UINotificationResearchComplete")
    end ) -- CreateRealTimeThread
  end -- if foundIncompatibleMods
end -- function end

---------------------------------------------- OnMsgs -----------------------------------------------


function OnMsg.NewHour(hour)
  if hour == 8 and g_CAIenabled and (not g_CAIoverride) then
  	CAIjobhunt()
  end -- once a day at 8AM
end -- OnMsg.LoadGame()

function OnMsg.ToggleLFPrint(modname, lfvar)
	-- use Msg("ToggleLFPrint", "CIA", "printdebug") to toggle
	if modname == "CIA" then
		if lfvar then
			if lfvar == "printdebug" then lf_printDebug = not lf_printDebug end
		else
			lf_print = not lf_print
		end -- if lfvar
  end -- if
end -- OnMsg.ToggleLFPrint(modname)