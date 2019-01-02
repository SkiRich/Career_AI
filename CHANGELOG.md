# Changelog for Career A.I.
## version 01/02/2019 2:19:56 PM
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
