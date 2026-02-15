class_name ActionUse
extends RefCounted
##action_use.gd
## Data packet describing one action being executed (user, action, targets, optional data)
## Per-use action request object to avoid mutating shared BattleAction resources


var battle_scene : BattleScene = null

#region To Include

##Battler performing the action
var user : Battler

##Action (resource) being used
var action : BattleAction

## Skill payload for USE_SKILL actions
var skill : Skill = null

## Item slot payload for USE_ITEM actions
var item_slot : InventorySlot = null

##Chosen targets for this action
var targets : Array[Battler]

## Options one-off extra data for the use of this action
## Example keys: "skill_level", "selected_menu_index", "override_hit", "default_target_focus", "free_cost"
var data : Dictionary

var action_type : BattleAction.ActionType

func _init(_user : Battler,	_action : BattleAction,	_targets : Array[Battler] = [],	_data : Dictionary = {})->void:
	user = _user
	action = _action
	targets = _targets.duplicate()
	data = _data.duplicate()
	action_type = action.type
	
func has_targets()-> bool: 
	return !targets.is_empty()
	
func first_target()->Battler:
	if targets.is_empty():
		return null
	return targets[0]
		
