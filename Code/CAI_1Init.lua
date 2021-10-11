-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018
-- Updated Oct 10th, 2021


local lf_print      = false -- Setup debug printing in local file
local lf_printDebug = false -- debug ChooseWorkplace
local lf_printRules = false -- debug Rules check
local lf_watchSpec  = "engineer" -- specialist type to watch during debug
                            -- Use if lf_print then print("something") end
                            -- use Msg("ToggleLFPrint", "CAI", "printdebug", "geologist") to toggle whating a jobspec
                            -- use Msg("ToggleLFPrint", "CAI", "printdebug") to watch all jobspecs

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
	local workplaces = UIColony.city_labels.labels.Workplace or empty_table

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
			  local wp = workplace[i]
				local numopenjobs = 0
				if CAIvalidateBld(wp) then -- check to make sure building is not destroyed  workplace.ui_working
				  -- need to check for closed shift now since the devs fucked up closed_workplaces for since shift buildings
				  numopenjobs = numopenjobs + (((not wp:IsClosedShift(1)) and (wp:GetFreeWorkSlots(1))) or 0)
				  numopenjobs = numopenjobs + (((not wp:IsClosedShift(2)) and (wp:GetFreeWorkSlots(2))) or 0)
				  numopenjobs = numopenjobs + (((not wp:IsClosedShift(3)) and (wp:GetFreeWorkSlots(3))) or 0)
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
-- exclude tourists, just in case
-- jobtype   : string, optional - gather all the colonists for any jobtype using jobtype = "thejobtype"
local function CAIgatherColonists(jobtype)
	local colonists = UIColony.city_labels.labels.Colonist or empty_table
	local jobhunters = {}

	for i = 1, #colonists do
		local c = colonists[i]
		if ((jobtype and c.specialist and c.specialist == jobtype) or ((not jobtype) and c.specialist and c.specialist ~= "none")) and c:CanWork() and
		   (not IsKindOfClasses(c.workplace, "School", "Sanatorium", "MartianUniversity")) and
		   ((not c.workplace) or (c.workplace and c.workplace.specialist ~= c.specialist)) and (not c.traits.Tourist) then
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
	  numopenslots[1] = (((not workplace:IsClosedShift(1)) and (workplace:GetFreeWorkSlots(1))) or 0)
	  numopenslots[2] = (((not workplace:IsClosedShift(2)) and (workplace:GetFreeWorkSlots(2))) or 0)
	  numopenslots[3] = (((not workplace:IsClosedShift(3)) and (workplace:GetFreeWorkSlots(3))) or 0)
	end -- if ValidateBuilding
	return numopenslots
end -- CAIgetFreeSlots(employer)



-- determine if the building traits are incompatible
local function CAIhasIncompatibleTraits(workplace, unit_traits)
  for _, trait in ipairs(workplace.incompatible_traits) do
    if unit_traits[trait] then
      return true
    end -- if
  end -- for
end -- function CAIhasIncompatibleTraits()


-- determine if colonist can work at a job with enforcement/traits
-- logic based on ShouldProc from workplacec.lua
local function CAIcanWorkHere(colonist, workplace)
  -- lets check out the building 
  if ValidateBuilding(workplace) and (colonist.avoid_workplace ~= workplace) and workplace.ui_working and (workplace.max_workers > 0) and
     (not workplace.specialist_enforce_mode or ((workplace.specialist or "none") == colonist.specialist)) and 
     (not CAIhasIncompatibleTraits(workplace, colonist.traits)) 
  then return true end 
  return false
end -- CAIcanWorkHere(colonist, workplace)


-- determine if colonist can move into dome with dome filters
-- determine if colonist is quarantined in their current dome
local function CAIcanMoveHere(colonist, workplace, dDome)
	local d_dome        = dDome or workplace.parent_dome or FindNearestObject(workplace.city.labels.Community, workplace)
	local c_canMove     = colonist.dome and colonist.dome.accept_colonists
	local eval          = TraitFilterColonist(d_dome.trait_filter, colonist.traits)
	if c_canMove and d_dome and d_dome.accept_colonists and eval >= 0 then
		return true
	else
		return false
	end -- if eval
end -- CAIcanMoveHere(colonist, workplace)

-- copy of ShuttleHub:GetGlobalLoad() from ShuttleHub.lua
local function ShuttleLoadOK(city)
  city = city or (UIColony and UIColony.city_labels) or empty_table
  local shuttles = 0
  local tasks = LRManagerInstance and LRManagerInstance:EstimateTaskCount()
  if tasks then
    for _, hub in ipairs(city.labels.ShuttleHub or empty_table) do
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

-- checks for any sponsor that has no commute penalty
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
	local UIColony = UIColony
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
		local retestApplicants = {}
		if applicants and #applicants > 0 and employers and #employers > 0 then
			if lf_print then
				print("--------------------------------------------")
				print("We have applicants and jobs to switch for job type: ", speclist[spec], " - #Applicants: ", #applicants, " #Employers: ", #employers)
			end -- if lf_print
			for i = 1, #employers do
			  -- test applicants list against an employer of that job type
			  -- if employer is not a match then move applicant to retestApplicants table and try the next applicant
			  -- remove applicant for the list of matched done below
			  -- when switching employers to test if no more applicants, move the retestApplicants back and try next employer
			  if (#applicants < 1) and (#retestApplicants > 0) then
			    if lf_print then print("** We have retest candidates: ", #retestApplicants) end
			    applicants = retestApplicants -- move the retest applicants
			    retestApplicants = {}  -- zero out the retest applicants
			  end -- if (#applicants < 1)
			  
				local numopenslots = CAIgetFreeSlots(employers[i])
				local displayEmployer = lf_print and {name = IT(employers[i].name ~= "" and employers[i].name or employers[i].display_name), 
							                                dome = IT((employers[i].parent_dome and employers[i].parent_dome.name) or FindNearestObject(employers[i].city.labels.Community, employers[i])),
							                                realm = employers[i]:GetMapID() or "N/A"} or empty_table
				
				for shift = 1, 3 do
				  -- if there are open job slots in this shift and we got applicants
					if numopenslots[shift] > 0 and #applicants > 0 then
						if lf_print then
							print("--------------------------------------------")
							print(string.format("Employer: %s in or near dome: %s has %s open slots in shift %s", displayEmployer.name, displayEmployer.dome, numopenslots[shift], shift))
						end -- if lf_print
						
						-- fill each slot with an applicant if possible
						for slot = 1, numopenslots[shift] do
						  local slotFilled = false
						  --if #applicants > 0 then
						  while (not slotFilled) and (#applicants > 0) do
						  	if lf_print then
						  		local aworkplace = applicants[1].workplace or "Unemployed"
						  		if aworkplace ~= "Unemployed" then aworkplace = aworkplace.name ~= "" and aworkplace.name or aworkplace.display_name end
						  		print(string.format("Applicant %s is moving from %s to %s", IT(applicants[1].name), IT(aworkplace), displayEmployer.name))
						  	end -- if lf_print
						  	
						  	-- if applicant1 can work here and reach building
						  	if CAIcanWorkHere(applicants[1], employers[i]) and applicants[1]:CanReachBuilding(employers[i]) then -- if they allowed to take the job, can walk or get a ride then move
						  	  local a_dome = applicants[1].dome or applicants[1].current_dome or applicants[1]:GetPos() -- current_dome is just in case the colonist is currently moving domes.
						  	  local e_dome = employers[i].parent_dome or FindNearestObject(employers[i].city.labels.Community, employers[i])
						  	  
						  	  ----- This section is for local domes in walking distance -----
						  	  if a_dome == e_dome or IsInWalkingDist(a_dome, e_dome) then
						  	  	-- if applicant can get to the job, then set it right away
						  	  	if a_dome == e_dome then
						  	  		-- if home dome
						  	  		if lf_print then print(string.format("Applicant %s is staying in home dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  	  if applicants[1].workplace and (applicants[1].workplace ~= employers[i]) then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	  applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	  	  slotFilled = true
						  	  	elseif ShouldMigrate() and a_dome.accept_colonists and e_dome:GetFreeLivingSpace() > 0 and CAIcanMoveHere(applicants[1], employers[i]) and CAIreserveResidence(applicants[1], e_dome) then
						  	  		-- not home but but can migrate in walking distance 
						  	  		if lf_print then print(string.format("Applicant %s is moving to dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  		if applicants[1].workplace and (applicants[1].workplace ~= employers[i]) then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	  applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	  		applicants[1]:SetForcedDome(e_dome)
						  	  		slotFilled = true
						  	  	elseif e_dome:CanColonistsFromDifferentDomesWorkServiceTrainHere() and AreDomesConnected(a_dome, e_dome) and a_dome.accept_colonists and e_dome.accept_colonists and a_dome.allow_work_in_connected then
						  	  		-- not home dome can commute to connected dome
						  	  		if lf_print then print(string.format("Applicant %s is commuting from %s to dome %s", IT(applicants[1].name), IT(a_dome.name) , IT(e_dome.name))) end
						  	  		if applicants[1].workplace and (applicants[1].workplace ~= employers[i]) then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	  applicants[1]:SetWorkplace(employers[i], shift) -- set their workpace
						  	  	  slotFilled = true
						  	    end -- if a_dome == e_dome
						  	    ----- This section is if they can migrate with LRTransport and live in same dome -----
						  	  elseif a_dome ~= e_dome and a_dome.accept_colonists and e_dome.accept_colonists and
						  	         IsTransportAvailableBetween(a_dome, e_dome) and IsLRTransportAvailable(e_dome.city) and ShuttleLoadOK(e_dome.city) and
						  	         CAIcanMoveHere(applicants[1], employers[i]) and CAIreserveResidence(applicants[1], e_dome) then
						  	  	-- not home dome must relocate
						  	  	-- relocate colonist and consider space for home
						  	  	-- obey dome filters
						  	  	-- check for LR Transport availability and the workload
						  	  	if lf_print then print(string.format("Applicant %s is relocating to dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	  	if applicants[1].workplace and (applicants[1].workplace ~= employers[i]) then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	applicants[1]:SetWorkplace(employers[i], shift)
						  	  	applicants[1]:SetForcedDome(e_dome)
						  	  	slotFilled = true
						  	  	----- This section is if they can migrate with LRTransport and live in connected dome -----
						  	  elseif a_dome ~= e_dome and a_dome.accept_colonists and e_dome.accept_colonists and
						  	         IsTransportAvailableBetween(a_dome, e_dome) and IsLRTransportAvailable(e_dome.city) and ShuttleLoadOK(e_dome.city) and
						  	         CAIcanMoveHere(applicants[1], employers[i]) then
						  	         	-- check conected domes if can move there and return the largest spaced one
						  	         	local hasSpace, targetDome = CAIcanReserveResInConnnectedDome(applicants[1], e_dome)
						  	         	if hasSpace and CAIreserveResidence(applicants[1], targetDome) then
						  	         		if lf_print then print(string.format("Applicant %s is relocating to connected dome %s", IT(applicants[1].name), IT(e_dome.name))) end
						  	         		if applicants[1].workplace and (applicants[1].workplace ~= employers[i]) then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  	        applicants[1]:SetWorkplace(employers[i], shift)
						  	  	        applicants[1]:SetForcedDome(targetDome)
						  	  	        slotFilled = true
						  	         	end -- if hasSpace
						  	  end --  if a_dome == e_dome or IsInWalkingDist
						  	  
						  	  -- whether the applicant failed or suceeded the secondary checks above, we have to move on, so 
						  	  -- remove the applicant, do not try this applicant again for this employer
						  	  table.remove(applicants, 1) -- remove the applicant from the applicant list
				  	  
						  	else -- cant work here
						  		if lf_print then 
						  		  print("Retry applicant - Applicant cant reach prospective employer, was not right for the job or was fired from this job")
						  		  print(string.format("Applicant realm: %s - Employment realm: %s", applicants[1]:GetMapID(), displayEmployer.realm)) 
						  		end -- if lf_print
						  		if i < #employers then
						  			-- remove the applicant but put him in the retry table to try another employer later since we have more to test
						  			table.insert(retestApplicants, applicants[1])
						  			table.remove(applicants, 1) -- remove the applicant from the applicant list
						  		else
						  		  -- this is our last employer ditch the applicant
						  		  table.remove(applicants, 1) -- remove the applicant from the applicant list
						  		end -- if #employers == 1
						  	end -- if CAIcanWorkHere(applicants[1], employers[i])

						  end -- while (not slotFilled) and (#applcants > 0) do
					
					  end -- for slot = 1, numopenslots[shift] do
					  
					end -- if numopenslots[shift] > 0 and #applicants > 0
					
				end -- for shift = 1, 3 do
				if lf_print then print("No more applicants available for employer: ", IT(employers[i].name ~= "" and employers[i].name or employers[i].display_name)) end
				
			end -- for i = 1, #employers do
    	if lf_print then
    		print("==========================================================")
    		print("=================== No More Employers ====================")
    	end -- if lf_print			
    else
    	if lf_print then
    		print("==========================================================")
    		print("No match for applicants and employers in:", speclist[spec])
    	end -- if lf_print
		end -- applicant and employers
	
	end -- spec = 1, #speclist do

end -- CAIjobhunt()


-- check current home dome versus job dome and if possible move to job dome
function CAIjobmigrate()
	local UIColony = UIColony
	local colonists = UIColony.city_labels.labels.Colonist or empty_table
	local count  = 0
  if lf_print then print("--- Starting CAIjobmigrate check ---") end
	for i = 1, #colonists do
		if colonists[i].workplace then
			local c  = colonists[i]
			local cw = c.workplace -- if unemployed, this is false
			local c_dome = c.dome or c.current_dome
			-- add a check for unemployed and dont try a migration
			local cw_dome = cw and cw.parent_dome or FindNearestObject(UIColony.city_labels.labels.Community, cw)
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
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then print("++ Specialist finding spec work: ", specialist) end
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, sworkplaces, true) -- true here to kick out non specs
  elseif (specialist ~= "none") and (#sworkplaces == 0) then
  	-- we got a specialist but no specialist specific workplaces just use the regular function but dont kick out anyone
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then print("-- Specialist finding non-spec work: ", specialist) end
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, workplaces, false) -- false here to not kickout non specs, find a job you bum
  elseif (specialist == "none") and (#nsworkplaces > 0) then
  	-- we got a non-specialist so find non-specialist work first dont kick anyone out.
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then print("++ NON Specialist finding no-spec work") end
  	best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, nsworkplaces, false) -- false here to not kickout anyone, find a job you bum
  end -- if (specialist ~= "none") and (#sworkplaces > 0)

  if best_bld and best_shift then
    -- if we got proper work and we can get there, then return that work
  	if lf_printDebug and ((not lf_watchSpec) or lf_watchSpec == specialist) then
  		local best_bld_dome = best_bld and (best_bld.parent_dome or FindNearestObject(unit.city.labels.Community, best_bld))
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
    	local best_bld_dome = ValidateBuilding(best_bld) and (best_bld.parent_dome or FindNearestObject(best_bld.city.labels.Community, best_bld))
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
        AddCustomOnScreenNotification("CAI_Notice", T{StringIdBase, "Career A.I."}, msgCIA, iconCIAnotice, nil, {expiration = g_CAInoticeDismissTime}, MainCity.map_id)
	      PlayFX("UINotificationResearchComplete")
    end ) -- CreateRealTimeThread
  end -- if foundIncompatibleMods
end -- function end

---------------------------------------------- OnMsgs -----------------------------------------------

function OnMsg.ClassesGenerate()

  -- re-write of CanReachBuilding(bld) in colonist.lua
  -- they are not checking realms and they used communities for some reason instead of domes
  local Old_Colonist_CanReachBuilding = Colonist.CanReachBuilding
  function Colonist:CanReachBuilding(bld)
    if not g_CAIenabled then return Old_Colonist_CanReachBuilding(self, bld) end -- shortcircuit
    if not ValidateBuilding(bld) then return false end -- short circuit bad building
    local my_dome = self.dome or empty_table
    local my_realm = self:GetMapID() or my_dome:GetMapID() or ""
    local dest_realm = bld:GetMapID() or ""
    if my_realm ~= dest_realm then return false end -- short circuit not on same map
    if my_dome ~= bld then
      local dest_dome = bld.parent_dome or FindNearestObject(bld.city.labels.Community, bld)
      dest_dome = not dest_dome and FindNearestObject(self.city.labels.Community, self) or dest_dome
      if my_dome ~= dest_dome and not IsInWalkingDist(my_dome or self:GetNavigationPos(), dest_dome) and (not my_dome or not IsTransportAvailableBetween(my_dome, dest_dome)) then
        return false
      end -- if
    end -- if my_dome ~= bld
    return true
  end -- Colonist:CanReachBuilding(bld)


  
  -- re-write from colonist.lua
  -- devs eliminated the jobbefore setting the avoid workplace - I just reversed the code.
  local Old_Colonist_GetFired = Colonist.GetFired
  function Colonist:GetFired()
    if not g_CAIenabled then return Old_Colonist_GetFired(self) end -- shortcircuit
    if not self.workplace then
      return
    end -- if
    self.avoid_workplace = self.workplace
    self.avoid_workplace_start = UIColony.day
    self:SetWorkplace(false)
    self:ChangeWorkplacePerformance()
  end -- function Colonist:GetFired()
  
end -- OnMsg.ClassesGenerate()


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