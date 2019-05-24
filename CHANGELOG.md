# Changelog for Career A.I.
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
