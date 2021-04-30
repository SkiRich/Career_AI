-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018
-- Updated March 24th, 2021


local lf_print      = false -- Setup debug printing in local file
local lf_printDebug = false -- debug ChooseWorkplace
local lf_printRules = false -- debug Rules check
local lf_watchSpec  = "engineer" -- specialist type to watch during debug
                            -- Use if lf_print then print("something") end
                            -- use Msg("ToggleLFPrint", "CAI", "printdebug", "geologist") to toggle

local ModDir = CurrentModPath
local iconCIAnotice = ModDir.."UI/Icons/CareerAINotice.png"
local StringIdBase = 17764701500 -- Career AI  : 701500 - 701599 this file: 50-99 Next: 55

local incompatibleMods = {
	{name = "Smarter Migration AI",      id = "1343552210"},
	{name = "Smarter Worker AI",         id = "1338867491"},
	{name = "Better AI",                 id = "1361377883"},
	{name = "Martian Economy",           id = "1340466409"},
	{name = "Improved Martian Economy",  id = "1575009362"},
} -- incompatibleMods

GlobalVar("g_CAIenabled", true)      -- var to turn on or off CAI
GlobalVar("g_CAIamateurCheck", true) -- var to check whether to bug or not anymore
GlobalVar("g_CAIminSpecialists", 20) -- the minimum number of specialists to wait when playing Amateur rule.

g_CAIoverride          = false  -- var to override CAI if incompatible mods detected
g_CAInoticeDismissTime = 15000  -- var to time the notification dismissal 15 seconds


local IT = _InternalTranslate

-- idea from ShouldProc from workplace.lua
-- added biome check for turned of domes
local function CAIvalidateBld(bld)
	local dome = bld:CheckServicedDome()
	if dome then
	  return ValidateBuilding(bld) and bld.ui_working and bld.max_workers > 0 and bld.max_workers and dome.ui_working
	else
		return -- short circuit since no nearby dome to live in.
	end -- if dome
end -- CAIvalidateBld(building)


-- gather all the open jobs that want specialists
-- jobtype   : string, optional - gather all the open jobs for any jobtype using jobtype = "thejobtype"
local function CAIgatherOpenJobs(jobtype)
	local openjobs = {counts = {}, employers = {}}
	local jobsbyspec = {}
	local workplaces = UICity.labels.Workplace or empty_table

  -- gather all jobs by spec type
	for i = 1, #workplaces do
		if workplaces[i].specialist then -- check to make sure it not nil first (mostly for poorly coded mods)
		  if not jobsbyspec[workplaces[i].specialist] then jobsbyspec[workplaces[i].specialist] = {} end -- setup sub-table
		  table.insert(jobsbyspec[workplaces[i].specialist], workplaces[i])
	  end -- if workplaces[i].specialist
	end -- for i

	for jobspec, workplace in pairs(jobsbyspec) do
		if (jobtype and jobspec == jobtype) or ((not jobtype) and jobspec ~= "none") then
			if not openjobs.employers[jobspec] then openjobs.employers[jobspec] = {} end -- setup sub-table
			if not openjobs.counts[jobspec] then openjobs.counts[jobspec] = 0 end -- setup sub-table
			for i = 1, #workplace do
				local numopenjobs = 0
				if CAIvalidateBld(workplace[i]) then -- check to make sure building is not destroyed  workplace.ui_working
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
-- gather colonists with non-pecialities working in specialty jobs
-- exclude colonists at school, sanatorium and university (shouldn't have specialists in university anyway)
-- exclude children and seniors that cannot work
-- jobtype   : string, optional - gather all the colonists for any jobtype using jobtype = "thejobtype"
local function CAIgatherColonists(jobtype)
	local colonists = UICity.labels.Colonist or empty_table
	local jobhunters = {}

	for i = 1, #colonists do
		local c = colonists[i]
		if ((jobtype and c.specialist and c.specialist == jobtype) or ((not jobtype) and c.specialist and c.specialist ~= "none")) and c:CanWork() and
		   (not IsKindOfClasses(c.workplace, "School", "Sanatorium", "MartianUniversity")) and
		   ((not c.workplace) or (c.workplace and c.workplace.specialist ~= c.specialist)) then
			-- colonist is a specialist
			-- colonist can work see Colonist:CanWork()
			-- is not in a school, sanatorium or MU
			-- jobless gets priority then specialists working in the wrong specialty
			if not jobhunters[c.specialist] then jobhunters[c.specialist] = {} end -- create sub-table
			table.insert(jobhunters[c.specialist], c)
		end
	end -- for i

	--ex(jobhunters)
	return jobhunters
end -- CAIgatherColonists()

-- returns free work slots that are open and active/not closed or shift closed
local function CAIgetFreeSlots(workplace)
	local numopenslots = {}
	if ValidateBuilding(workplace) then -- check to make sure building is not destroyed
	  numopenslots[1] = workplace:GetFreeWorkSlots(1) or 0
	  numopenslots[2] = workplace:GetFreeWorkSlots(2) or 0
	  numopenslots[3] = workplace:GetFreeWorkSlots(3) or 0
	end -- if ValidateBuilding
	return numopenslots
end -- CAIgetFreeSlots(employer)


-- determine if colonist can work at the job with enforcement
-- currently not used
local function CAIcanWorkHere(colonist, workplace)
  if workplace.specialist_enforce_mode then
    if (workplace.specialist or "none") ~= (colonist.specialist or "none") then
      return false
    else
    	return true
    end -- if workplace specialties dont match
  else
  	return true
  end
end -- CAIcanWorkHere(colonist, workplace)


-- determine if colonist can move into dome with dome filters
-- determine if colonist is quarantined in their current dome
local function CAIcanMoveHere(colonist, workplace, dDome)
	local d_dome        = dDome or workplace.parent_dome or FindNearestObject(UICity.labels.Dome, workplace)
	local c_canMove     = colonist.dome and colonist.dome.accept_colonists
	local eval          = TraitFilterColonist(d_dome.trait_filter, colonist.traits)
	if c_canMove and d_dome.accept_colonists and eval >= 0 then
		return true
	else
		return false
	end -- if eval
end -- CAIcanMoveHere(colonist, workplace)

-- copy of ShuttleHub:GetGlobalLoad()
local function ShuttleLoadOK()
	local UICity = UICity
  local shuttles = 0
  local tasks = LRManagerInstance and LRManagerInstance:EstimateTaskCount()
  if tasks then
    for _, hub in ipairs(UICity.labels.ShuttleHub or empty_table) do
      if hub.working or hub.suspended then
        shuttles = shuttles + #hub.shuttle_infos
      end
    end
  end
  local shuttle_load
  if not tasks or shuttles == 0 then
    shuttle_load = 0
  elseif tasks < shuttles then
    shuttle_load = 1
  elseif tasks < 3 * shuttles then
    shuttle_load = 2
  else
    shuttle_load = 3
  end
  if shuttle_load == 1 or shuttle_load == 2 then return true end
  return false
end -- ShuttleLoadOK()

-- checks for any sponsor that has no comute penalty
local function ShouldMigrate()
	local sponsor = GetMissionSponsor()
	if sponsor.id == "Brazil" then return false end
	return true
end -- ShouldMigrate()

-- try and reserve a residence before migration
-- altered for Tito
local function CAIreserveResidence(colonist, dome)
	if dome:GetFreeLivingSpace() > 0 then
	  local aptBldgs = (dome.labels and dome.labels.Residence) or empty_table
	  local aptBldgsWithSpace = {}

	  -- find all the free apts
	  for i = 1, #aptBldgs do
	  	-- test for exclusivity compatibility for new Tito mechanic
	  	if aptBldgs[i].exclusive_trait then
	  		for trait in pairs(colonist.traits) do
	  			if trait == aptBldgs[i].exclusive_trait and aptBldgs[i]:GetFreeSpace() > 0 then aptBldgsWithSpace[#aptBldgsWithSpace+1] = aptBldgs[i] end
	  		end -- for trait
	  	elseif aptBldgs[i]:GetFreeSpace() > 0 then
	  		aptBldgsWithSpace[#aptBldgsWithSpace+1] = aptBldgs[i]
	  	end --if aptBldgs[i].exclusive_trait
	  	-- original code pre Tito
	  	-- if aptBldgs[i]:GetFreeSpace() > 0 then aptBldgsWithSpace[#aptBldgsWithSpace+1] = aptBldgs[i] end
	  end -- for i

	  -- try and get a reservation
	  for i = 1, #aptBldgsWithSpace do
	  	if aptBldgsWithSpace[i]:ReserveResidence(colonist) then	return true end
	  end -- for i

	end -- if dome:GetFreeLivingSpace()
	return false -- default no space
end -- CAIreserveResidence()

-- try and reserve a residence before migration check in a connected dome
-- check connected domes if can move there and return the largest spaced one
local function CAIcanReserveResInConnnectedDome(colonist, e_dome)
	local haveSpace = false
	if not e_dome then return false, false end -- short circuit if empty
	local connectedDomes = e_dome:GetConnectedDomes()
	local connectedDomesSpace = {}
	local largestSpaceDome = {}
	for dome, result in pairs(connectedDomes) do
		-- load up table with domes that have space
		if result and (dome:GetFreeLivingSpace() > 0) and CAIcanMoveHere(colonist, nil, dome) then
			connectedDomesSpace[dome] = dome:GetFreeLivingSpace()
			haveSpace = true
			if #largestSpaceDome == 0 then
				largestSpaceDome[1] = dome
				largestSpaceDome[2] = connectedDomesSpace[dome]
			elseif connectedDomesSpace[dome] > largestSpaceDome[2] then
				largestSpaceDome[1] = dome
				largestSpaceDome[2] = connectedDomesSpace[dome]
			end -- if #largestSpaceDome
		end -- if result
	end -- for dome, result
	--ex(connectedDomesSpace)
	--ex(largestSpaceDome)
	--ex((#largestSpaceDome > 0 and largestSpaceDome[1]) or {})
	return haveSpace, (#largestSpaceDome > 0 and largestSpaceDome[1]) or {}
end -- CAIreserveResInConnnectedDome()


-- main function called once daily to move specialists around to better jobs
-- jobtype   : string, optional - jobhunt for jobtype using jobtype = "thejobtype"
function CAIjobhunt(jobtype)
	local UICity = UICity
	local FindNearestObject = FindNearestObject
	local openjobs = CAIgatherOpenJobs(jobtype)
	local jobhunters = CAIgatherColonists(jobtype)
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
						  	local avoid_workplace = applicants[1].avoid_workplace or ""
						  	if avoid_workplace ~= employers[i]  and applicants[1]:CanReachBuilding(employers[i]) then -- if they alowed to take the job, can walk or get a ride then move
						  	  local a_dome = applicants[1].dome or applicants[1].current_dome or applicants[1]:GetPos() -- current_dome is just in case the colonist is currently moving domes.
						  	  local e_dome = employers[i].parent_dome or FindNearestObject(UICity.labels.Dome, employers[i])
						  	  ----- This section is for local domes in walking distance -----
						  	  if a_dome == e_dome or IsInWalkingDistDome(a_dome, e_dome) then
						  	  	-- if applicant can get to the job, then set it right away
						  	  	if a_dome == e_dome then
						  	  		-- if home dome
						  	  		if lf_print then print(string.format("Applicant %s is staying in home dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  	  if applicants[1].workplace then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	  applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	  	elseif ShouldMigrate() and a_dome.accept_colonists and e_dome.accept_colonists and e_dome:GetFreeLivingSpace() > 0 and CAIcanMoveHere(applicants[1], employers[i]) and CAIreserveResidence(applicants[1], e_dome) then
						  	  		-- not home but but can migrate in walking distance
						  	  		if lf_print then print(string.format("Applicant %s is moving to dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  		if applicants[1].workplace then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	  applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	  		applicants[1]:SetForcedDome(e_dome)
						  	  	elseif e_dome:CanColonistsFromDifferentDomesWorkServiceTrainHere() and a_dome.accept_colonists and e_dome.accept_colonists and a_dome.allow_work_in_connected then
						  	  		-- not home dome can commute
						  	  		if lf_print then print(string.format("Applicant %s is commuting to dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  		if applicants[1].workplace then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	  applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	    end -- if a_dome == e_dome
						  	    ----- This section is if they can migrate with LRTransport and live in same dome -----
						  	  elseif a_dome ~= e_dome and a_dome.accept_colonists and e_dome.accept_colonists and
						  	         IsTransportAvailableBetween(a_dome, e_dome) and IsLRTransportAvailable(e_dome.city) and ShuttleLoadOK() and
						  	         CAIcanMoveHere(applicants[1], employers[i]) and CAIreserveResidence(applicants[1], e_dome) then
						  	  	-- not home dome must relocate
						  	  	-- relocate colonist and consider space for home
						  	  	-- obey dome filters
						  	  	-- check for LR Transport availability and the workload
						  	  	if lf_print then print(string.format("Applicant %s is relocating to dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  	if applicants[1].workplace then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	applicants[1]:SetWorkplace(employers[i], shift)
						  	  	applicants[1]:SetForcedDome(e_dome)
						  	  	----- This section is if they can migrate with LRTransport and live in connected dome -----
						  	  elseif a_dome ~= e_dome and a_dome.accept_colonists and e_dome.accept_colonists and
						  	         IsTransportAvailableBetween(a_dome, e_dome) and IsLRTransportAvailable(e_dome.city) and ShuttleLoadOK() and
						  	         CAIcanMoveHere(applicants[1], employers[i]) then
						  	         	-- check conected domes if can move there and return the largest spaced one
						  	         	local hasSpace, targetDome = CAIcanReserveResInConnnectedDome(applicants[1], e_dome)
						  	         	if hasSpace and CAIreserveResidence(applicants[1], targetDome) then
						  	         		if lf_print then print("Test Connecting Dome migration Function operating") end
						  	  	        applicants[1]:SetWorkplace(employers[i], shift)
						  	  	        applicants[1]:SetForcedDome(targetDome)
						  	         	end -- if hasSpace
						  	  end --  if a_dome == e_dome or IsInWalkingDist
						  	  table.remove(applicants, 1)
						  	else
						  		if lf_print then print("Applicant cant reach prospective employer") end
						  		if #employers == 1 and #applicants > 1 then
						  			-- remove the applicant if we can try another applicant for this job and its the only job
						  			table.remove(applicants, 1)
						  		end -- if #employers == 1
						  	end -- if applicants[1]:CanReachBuilding(employers[i])
						  else
						  	if lf_print then print("No more applicants available for employer: ", IT(employers[i].name ~= "" and employers[i].name or employers[i].display_name)) end
						  end -- if #applicants > 0
					  end -- for slot
					end -- if numopenslots[shift] > 0
				end -- for shift
			end -- for i
    else
    	if lf_print then
    		print("==========================================================")
    		print("No match for applicants and employers in:", speclist[spec])
    	end -- if lf_print
		end -- applicant and employers
	end -- for

end -- CAIjobhunt()


-- check current home dome versus job dome and if possible move to job dome
function CAIjobmigrate()
	local UICity = UICity
	local colonists = UICity.labels.Colonist or empty_table
	local count  = 0
  if lf_print then print("--- Starting CAIjobmigrate check ---") end
	for i = 1, #colonists do
		if colonists[i].workplace then
			local c  = colonists[i]
			local cw = c.workplace -- if unemployed, this is false
			local c_dome = c.dome or c.current_dome
			-- add a check for unemployed and dont try a migration
			local cw_dome = cw and cw.parent_dome or FindNearestObject(UICity.labels.Dome, cw)
			if cw and c_dome and cw_dome and (not IsKindOfClasses(cw, "School", "Sanatorium", "MartianUniversity")) and c_dome ~= cw_dome and cw_dome:GetFreeLivingSpace() > 0 and
			   CAIcanMoveHere(c, cw) and CAIreserveResidence(c, cw_dome) then
				  c:SetForcedDome(cw_dome)
				  count = count + 1
				  if lf_print then print(string.format("Colonist %s is moving from %s to %s", IT(c.name), IT(c_dome.name), IT(cw_dome.name))) end
			elseif not cw then
				if lf_print then print(string.format("Colonist %s is Jobless in dome %s", IT(c.name), IT(c_dome.name))) end
			end -- if c_dome ~= cw_dome
		end -- if
	end -- for i
	if lf_print then print("Total colonist moves: ", count) end
end -- CAIjobmigrate()


-- re-write original function from workplace.lua
-- force specialist to choose specialist work first if available otherwise anyplace
-- force non-specialist to choose non-specialist work first if available, otherwise anyplace
local Old_ChooseWorkplace = ChooseWorkplace
function ChooseWorkplace(unit, workplaces, allow_exchange)
	-- short circuit if disabled
	if (not g_CAIenabled) or g_CAIoverride then
		return Old_ChooseWorkplace(unit, workplaces, allow_exchange)
  end -- if disabled

  -- short circuit for colonists working at Schools(Children ONLY), Sanatoriums and University's
  if IsKindOfClasses(unit.workplace, "School", "Sanatorium", "MartianUniversity") then
  	if lf_print then print(string.format("***** Colonists %s is at a School, Sanatorium or MU *****", IT(unit.name))) end
  	return Old_ChooseWorkplace(unit, workplaces, allow_exchange)
  end -- if in Sanatorium

  local sworkplaces  = {} -- specialist workplaces
  local nsworkplaces = {} -- non-specialist workplaces
  local specialist = unit.specialist or "none"

  for i = 1, #workplaces do
  	if workplaces[i].specialist and workplaces[i].specialist == specialist then
  		sworkplaces[#sworkplaces+1] = workplaces[i]
  	elseif (not workplaces[i].specialist) or workplaces[i].specialist == "none" then
  		nsworkplaces[#nsworkplaces+1] = workplaces[i]
  	end -- if workplaces[i]
  end -- for i

  if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then
  	local unit_dome = unit.dome or unit.current_dome or "Unknown"
  	print("-------------------------- ChooseWorkplace ----------------------------")
  	print(string.format("Specialist: %s - %s from %s", specialist, IT(unit.name), IT(unit_dome.name or unit_dome)))
  	print("Eligible specialist workplaces: ", #sworkplaces)
  	print("Eligible non-specialist workplaces: ", #nsworkplaces)
  end -- if lf_printDebug

  local best_bld, best_shift, best_to_kick, best_specialist_match

  -- lets try and put people where they work best
  if (specialist ~= "none") and (#sworkplaces > 0) then
  	-- we got specialist workplaces and a specialist go find a spot and kick out non specs
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then print("++ Specialist can find spec work") end
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, sworkplaces, true) -- true here to kick out non specs
  elseif (specialist ~= "none") and (#sworkplaces == 0) then
  	-- we got a specialist but no specialist specific workplaces just use the regular function but dont kick out anyone
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then print("-- Specialist has NO spec work") end
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, workplaces, false) -- false here to not kickout non specs, find a job you bum
  elseif (specialist == "none") and (#nsworkplaces > 0) then
  	-- we got a non-specialist so find non-specialist work first dont kick anyone out.
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then print("++ NON Specialist can find work") end
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, nsworkplaces, false) -- false here to not kickout anyone, find a job you bum
  end -- if (specialist ~= "none") and (#sworkplaces > 0)

  if best_bld and best_shift then
    -- if we got proper work and we can get there, then return that work
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then
  		local best_bld_dome = best_bld and (best_bld.parent_dome or FindNearestObject(UICity.labels.Dome, best_bld))
  	  print("Best Bld: ", (best_bld and IT(best_bld.name ~= "" and best_bld.name or best_bld.display_name)), " located at: ", IT(best_bld_dome.name))
  	  print("Best Shift: ", best_shift)
  	  print(string.format("Best Kick: %s - %s", (best_to_kick and IT(best_to_kick.name) or ""), (best_to_kick and best_to_kick.specialist or "")  ))
  	  print("Best Spec Match: ", best_specialist_match)
  	  print("---------------------------------------------------------------------")
  	end -- if lf_printDebug
  else
  	-- we got no work so lets just ask anyway, but dont kick anyone out to prevent job hopping
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, workplaces, false) -- use default and prevent job hopping.
    if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then
    	local best_bld_dome = best_bld and (best_bld.parent_dome or FindNearestObject(UICity.labels.Dome, best_bld))
    	print("===========================================================")
    	print("------+++++= Default ChooseWorkplace in Effect =+++++------")
    	print("===========================================================")
    	print("Workplaces with jobs : ", #workplaces)
    	print("Specialist Workplaces: ", #sworkplaces)
    	print("Non-Spec Workplaces  : ", #nsworkplaces)
  	  print("Best Bld: ", (best_bld and IT(best_bld.name ~= "" and best_bld.name or best_bld.display_name)), " located at: ", best_bld_dome and IT(best_bld_dome.name))
  	  print("Best Shift: ", best_shift)
  	  print(string.format("Best Kick: %s - %s", (best_to_kick and IT(best_to_kick.name) or ""), (best_to_kick and best_to_kick.specialist or "")  ))
  	  print("Best Spec Match: ", best_specialist_match)
  	  print("-----------------------------------------------------------")
    end -- if lf_printDebug
  end -- if best_bld and best_shift

  -- return vars
  return best_bld, best_shift, best_to_kick, best_specialist_match

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
        	ModLog(string.format("CAI found an incompatible mod: %s", foundIncompatibleMods[i]))
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
	-- specialists jobhunt
  if hour == 8 and g_CAIenabled and (not g_CAIoverride) then
  	CAIjobhunt()
  end -- once a day at 8AM

  -- non-specialist jobhunt
  if hour == 16 and g_CAIenabled and (not g_CAIoverride) then
  	CAIjobhunt("none")
  end -- once a day at 8AM

  -- job migrate AI
  if hour == 22 and g_CAIenabled and ShouldMigrate() and (not g_CAIoverride) then
  	CAIjobmigrate()
  end -- once a day at 8AM

end -- OnMsg.NewHour(hour)

function OnMsg.ToggleLFPrint(modname, lfvar, jobtype)
	-- use Msg("ToggleLFPrint", "CAI", "printdebug") to toggle
	if modname == "CAI" then
		if lfvar then
			if lfvar == "printdebug" then lf_printDebug = not lf_printDebug end
		else
			lf_print = not lf_print
		end -- if lfvar
  end -- if
  lf_watchSpec = jobtype
end -- OnMsg.ToggleLFPrint(modname)