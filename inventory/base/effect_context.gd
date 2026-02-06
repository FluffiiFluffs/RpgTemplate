class_name EffectContext
extends RefCounted

enum Mode { FIELD, BATTLE }
var mode : int = Mode.FIELD

var user_actor : ActorData = null

var battle_scene : BattleScene = null
var status_system : StatusSystem = null

# Canonical names used by Effect helpers and battle resolver
var current_target_battler : Battler = null
var source_item : Item = null

# Legacy aliases, kept so older code can still read something sensible
var queued_battle_messages : Array[String] = []
var queued_battle_message_targets : Array[Battler] = []

# Optional battle execution context for status hooks and attribution.
var current_user_battler : Battler = null
var current_action_use : ActionUse = null



func queue_battle_message(text : String, target_battler : Battler = null) -> void:
	if text == "":
		return
	queued_battle_messages.append(text)
	queued_battle_message_targets.append(target_battler)
