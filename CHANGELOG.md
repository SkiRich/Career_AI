# Changelog for Career A.I.
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
