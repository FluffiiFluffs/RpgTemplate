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

func queue_battle_message(text : String) -> void:
	if text == "":
		return
	queued_battle_messages.append(text)
