class_name CutsceneMaxVitals
extends CutsceneAction
## Cutscene Action used to max out party member(s) vitals


## If true, all party members vitals are set to the max (HP/SP)
@export var all_party_members : bool = false

## If true, negative status effects will be removed (inn/camp/rest)
@export var remove_status_effects : bool = false

## Not used if all_party_members is true
@export var party_member_slot : int = 0
