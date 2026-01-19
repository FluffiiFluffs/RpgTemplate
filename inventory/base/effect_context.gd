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
var target_battler : Battler = null
var souce_item : Item = null
