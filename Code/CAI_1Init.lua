-- Code developed for Automated Tradepad
-- Author @SkiRich
-- All rights reserved, duplication and modification prohibited.
-- You may not copy it, package it, or claim it as your own.
-- Created Dec 24th, 2018


local lf_print = true -- Setup debug printing in local file
                       -- Use if lf_print then print("something") end

local IT = _InternalTranslate

-- gather all the open jobs that want specialists
function CAIgatherOpenJobs()
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
function CAIgatherColonists()
	local colonists = UICity.labels.Colonist or empty_table
	local jobhunters = {}

	for i = 1, #colonists do
		local c = colonists[i]
		if c.specialist and c.specialist ~= "none" and c:_IsWorkStatusOk() and (not IsKindOf(c.workplace, "Sanatorium")) and ((not c.workplace) or (c.workplace and c.workplace.specialist ~= c.specialist)) then
			-- colonist is a specialist
			-- colonist can work see Colonist:_IsWorkStatusOk()
			-- is not in a sanatorium
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


-- re-write original function from workplace.lua
local Old_ChooseWorkplace = ChooseWorkplace
function ChooseWorkplace(unit, workplaces, allow_exchange)
  local sworkplaces = {}
  local specialist = unit.specialist or "none"

  for i = 1, #workplaces do
  	if workplaces[i].specialist == specialist then sworkplaces[#sworkplaces+1] = workplaces[i] end
  end -- for i

  if #sworkplaces > 0 then
  	local best_bld, best_shift, best_to_kick, best_specialist_match = Old_ChooseWorkplace(unit, sworkplaces, true)
    if best_bld and best_shift then
    	-- if we got specialist work, then return that work
      return best_bld, best_shift, best_to_kick, best_specialist_match
    end -- if best_bld
  end -- if there are specialist workplaces for the colonist

  -- use old function as default
  return Old_ChooseWorkplace(unit, workplaces, false)
end -- ChooseWorkplace(unit, workplaces, allow_exchange)


function CAIjobhunt(jobtype)
	local openjobs = CAIgatherOpenJobs()
	local jobhunters = CAIgatherColonists()
	local totalopenjobs = 0

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

	if jobtype then
		local applicants = jobhunters[jobtype]
		local employers = openjobs.employers[jobtype]
		if applicants and #applicants > 0 and employers and #employers > 0 then
			if lf_print then print("We have applicants and jobs to switch - Applicants: ", #applicants, " Employers: ", #employers) end
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
						  	  if applicants[1].workplace then applicants[1]:GetFired() end -- if currently working then fire them.
						  	  local a_dome = applicants[1].dome
						  	  local e_dome = employers[i].parent_dome
						  	  if a_dome == e_dome or IsInWalkingDist(a_dome, e_dome) then
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
    	if lf_print then print("No match for applicants and employers in:", jobtype) end
		end -- applicant and employers
	else
		print("No Code Here Yet")
	end



end -- CAIjobhunt()


---------------------------------------------- OnMsgs -----------------------------------------------


function OnMsg.LoadGame()


end -- OnMsg.LoadGame()