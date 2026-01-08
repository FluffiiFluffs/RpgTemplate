class_name ActionUse
extends RefCounted
##action_use.gd
## Data packet describing one action being executed (user, action, targets, optional data)
## Per-use action request object to avoid mutating shared BattleAction resources


#region Do NOT Include!
var battle_scene : BattleScene = null
#
func _ready()->void:
	pass
	
func decide_target()->void:
	pass

func apply_damage_to_target()->void:
	pass
	
#endregion Do NOT Include!

#region To Include

##Battler performing the action
var user : Battler

##Action (resource) being used
var action : BattleAction

##Chosen targets for this action
var targets : Array[Battler]

## Options one-off extra data for the use of this action
## Example keys: "item_slot", "skill_level", "selected_menu_index", "override_hit"
var data : Dictionary

var action_type : BattleAction.ActionType

func _init(_user : Battler,	_action : BattleAction,	_targets : Array[Battler] = [],	_data : Dictionary = {})->void:
	user = _user
	action = _action
	targets = _targets.duplicate()
	data = _data.duplicate()
	
func has_targets()-> bool: 
	return !targets.is_empty()
	
func first_target()->Battler:
	if targets.is_empty():
		return null
	return targets[0]
		
