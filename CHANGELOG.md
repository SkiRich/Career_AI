# Changelog for Career A.I.
## [v1.8.2] 09/24/21 3:36:59 AM

#### Added
- function Colonist:GetFired() - re-write to fix the developers code

#### Fixed Issues
- colonist came back after being fired

--------------------------------------------------------
## [v1.8.1] 09/22/21 2:35:36 PM
#### Changed
- debug texts to make it eaier to spot during debug
- various comments
- replaced MainCity with UIColony
- function CAIgatherOpenJobs(jobtype)  - now chebcking for closed shifts in adition to open slots
- function CAIgetFreeSlots(workplace)  - now checking for closed shifts in adition to open slots
- function CAIcanMoveHere(colonist, workplace, dDome) - improved logic
- local function ShuttleLoadOK(city) now uses the employer city to test for load.
- various debug improvments
- using InWalkingDist instead of InWalkingDistDome in job hunt routines

#### Added

#### Removed

#### Fixed Issues
- new patch no longer reports closed slots when closing entire shifts.  workers could be assigned to a slot when a shift was closed.
- issue with wandering colonists across map for work.

#### Open Issues

#### Deprecated

#### Todo

--------------------------------------------------------
## v1.8.0 09/10/2021 3:42:09 AM
#### Changed
- Picard version bump
- Replaced UICity with MainCity
- Added MainCity.map_id to AddCustomNotifications function
- Tweeked some debugs

#### Todo
- Add Underground

--------------------------------------------------------
## v1.7.5  06/24/2021 10:43:35 PM
#### Changed
- CAI_2ModConfig.lua file - added lf_printRules local var

#### Fixed Issues
- throwing error for not defining lf_printRules

--------------------------------------------------------
## v1.7.4 04/30/2021 3:33:21 PM
#### Changed
- local function ModOptions() - Needed to add check to ModConfig function.
- function CAIcheckAmateurs(gamestart) is now local and moved to ModConfig file
- local function CAIamateurPopup() moved to ModConfig file
- g_ModConfigLoaded is now local ModConfigLoaded
- CAIcheckAmateurs(gamestart) to include new ModOptions

#### Added
- WaitForModConfig()

#### Removed

#### Fixed Issues
- Error spam in log for modoptions changes if user does not have modconfig

#### Open Issues

#### Deprecated

#### Todo

--------------------------------------------------------
## v1.7.3 03/24/2021 11:50:27 PM
#### Changed
- function CAIreserveResidence - updated for the new exclusive mechanic
- CAIjobmigrate() - added aditional checks for workplace = false

##### Added
- Mod Options and tied it to Mod Config Reborn

#### Fixed Issues
- dumb lf_print syntax issue with indexs

--------------------------------------------------------
## 1.7.2 09/24/2020 6:42:15 PM
#### Changed
- Line 370

#### Fixed Issues
- Line 370 added check for nil for colonist workplaces.  Possible issue when no workplace is presented.

--------------------------------------------------------
# Changelog for Career A.I.
## v1.7.1 02/02/2020 1:06:11 AM
#### Changed
- CAIamateurPopup()

#### Added
- Aded 15 second delay to thread that warns about amateur rule at start of game

#### Fixed Issues
- Game hang when amateur rule is in effect

--------------------------------------------------------
## v1.7.0 06/08/2019 9:56:41 PM

#### Added
- function CAIcheckAmateurs(gamestart)
- OnMsg.NewDay()
- Mod config Options

#### Fixed Issues
- Turns off CAI until 20 specialists are in colony when playing Amateurs game rules

--------------------------------------------------------
## v1.6.0 06/08/2019 2:45:59 PM
#### Changed
- ChooseWorkplace()

#### Added
- added code to do the following more effectively
  - specialists take specialist jobs first then non-specialist work
  - non-specialists take non-specialists jobs first then any job

#### Fixed Issues
- optimized colonist ChooseWorkPlace() job selection process

--------------------------------------------------------
## v1.5.0 06/04/2019 6:25:11 PM
#### Changed
- Various syntax changes to code.
- function CAIcanMoveHere(colonist, workplace, dDome)
  - can now pass dome or workplace as test.

#### Added
- function CAIcanReserveResInConnnectedDome(colonist, e_dome)
  - try and reserve a residence before migration check in a connected dome

#### Fixed Issues
- Colonists never reserved residences in connecting domes using jobhunting ai.  Now they can as a last resort.

--------------------------------------------------------
## v1.4.0 05/24/2019 3:11:45 AM
#### Changed
- default lf_watchSpec
- CAIjobhunt(jobtype)
- CAIjobmigrate()

#### Added
- local function CAIreserveResidence(colonist, dome)

#### Fixed Issues
- homeless colonists due to migration without reservation.  Added reservation function.

--------------------------------------------------------
## v1.3.0 05/23/2019 6:59:15 PM
#### Changed
- CAIcanMoveHere(colonist, workplace)
  - added code to not move colonist if in a quarantined dome

#### Added
- Added School to the IsKind of Classes function for migrate and job hunt

#### Removed

#### Fixed Issues
- Children were being ejected from nursuries when schools where in a different dome.
- Moving colonists did not respect quarantined domes

#### Open Issues

#### Deprecated

#### Todo

--------------------------------------------------------
## V1.2.1 05/21/2019 3:10:14 AM
#### Changed
- ChooseWorkplace

#### Added
- Added School to short circuit.
  - if IsKindOfClasses(unit.workplace, "School", "Sanatorium", "MartianUniversity") then

#### Fixed Issues
- Children were being ejected from nursuries when schools where in a different dome.

--------------------------------------------------------
## 1.2.0 01/16/2019 10:34:14 PM
#### Changed
- CAIjobhunt(jobtype) to check for Brazil and Shuttle Workload
- NMewHour to check for Brazil

#### Added
- ShouldMigrate() checks for Brazil
- ShuttleLoadOK() check for shuttle load of 1 or 2

#### Fixed Issues
- Suicidal walking colonists

--------------------------------------------------------
## 1.1.1 01/03/2019 8:13:13 PM
#### Changed
- CAIjobhunt()

#### Added
- Added aditional LRTranport check

#### Open Issues
- suicidal colonists during heavy shuttle work load
  - two reports
  - waiting till more folks report issue to add addition options for workload

--------------------------------------------------------
## 1.0.2 01/02/2019 2:19:56 PM
#### Changed
- CAIgatherOpenJobs()
- CAIjobhunt(jobtype)
  - added avoid_workplace check and remove applicant if they cant reach the employer

#### Added
- function CAIvalidateBld(bld) - biome checks to CAIgatherOpenJobs()

#### Fixed Issues
- Colonists going into turned off buildings and turned off domes.

--------------------------------------------------------
## 1.0.1 12/31/2018 4:31:17 PM

#### Added
- Martian Economy to the incompatible list
- Improved Martian Economy to the incompatible list

--------------------------------------------------------
## v0.08 12/30/2018 5:51:13 PM
#### Changed
- NewHour()
- various syntax around CIA and CAI for TogglePrint

#### Added
- CAIjobmigrate()

--------------------------------------------------------
## v0.07 12/30/2018 4:28:33 AM
#### Changed
- ChooseWorkplace() -- redesigned it to prevent job hopping

#### Added
- ModLog for incompat mods alerts

#### Fixed Issues
- job hopping - specialists working in non-spec jobs seem to leave and come back.  Need to diagnose ChooseWorkplace.

#### Todo
- create job migration AI

--------------------------------------------------------
## v0.06 12/29/2018 6:11:05 PM
#### Changed
- CAIgatherOpenJobs() to CAIgatherOpenJobs(jobtype)  now includes lookup for jobtype if specified
- CAIgatherColonists() to CAIgatherColonists(jobtype)
- CAIjobhunt() to CAIjobhunt(jobtype)

#### Added
- added functionality for jobtype jobhunting
- function CAIcanWorkHere(colonist, workplace) -- currently not used
- function CAIcanMoveHere(colonist, workplace)
- job hunting AI for non-specialists

#### Todo
- create job migration AI

--------------------------------------------------------
## v0.05 12/29/2018 4:28:08 AM
#### Changed
- ChangeWorkpace() -- allowed for none speciality
- IsWorkStatusOK() to CanWork()

#### Added
- added logic to CAIjobhunt() to make sure applicant can migrate and/or work in the dest dome.

#### Removed
- old not needed code

#### Todo
- Create job hunting AI for non-specialists
- create job migration AI
- test none specialists

--------------------------------------------------------
## v0.04 12/29/2018 4:01:55 AM
#### Changed
- CIA to CAI syntax
- set CAIjobhunt to run once a day at 8am

#### Added
- incompatible mods checks and overrides

--------------------------------------------------------
## v0.03 12/28/2018 3:05:16 PM
#### Changed
- default ChangeWorkplace returned allow_exchange param
- IsInWalkingDist to IsInWalkingDistDome

#### Added
- code to override functions
- mod config options
- notifications on enabed or disabled AI

#### Todo

--------------------------------------------------------
## v0.02 12/27/2018 8:38:41 PM

#### Added
- code to make specialists look for specialist jobs

#### Todo
- cycle through all specialist types
- set career ai to run once a day
- mod config files

--------------------------------------------------------
## v0.01 12/24/2018 12:59:36 AM

Initial Mod Files

--------------------------------------------------------
