class_name StatusEffectPoison
extends StatusEffect

@export_category("Poison Tuning")
@export_range(0.0, 1.0, 0.0001) var battle_max_hp_percent_per_turn : float = 0.0
@export_range(0.0, 1.0, 0.0001) var field_max_hp_percent_per_step : float = 0.0
@export_range(0.0, 1.0, 0.0001) var stat_percent_decrease : float = 0.0

var _last_tick_status_system_id : int = 0
var _last_tick_turn_id : int = -1
var _stats_applied : bool = false
@export_category("Poison Identity")
@export var tier_name : String = "Poison"

const _SOURCE_KEY : StringName = &"status_poison"


func _init() -> void:
	kind = StatusKind.AILMENT
	scope = Scope.ALL

	exclusive_group_id = &"poison"
	exclusive_rank = 0
	remove_on_death = true

	expire_timing = ExpireTiming.NONE


func on_apply(_status_system : StatusSystem) -> void:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_apply_stat_decrease(actor)


func on_remove(_status_system : StatusSystem) -> void:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_remove_stat_decrease(actor)


func get_battle_dot_damage(actor : ActorData) -> int:
	if actor == null:
		return 0

	var max_hp : int = actor.get_max_hp()
	var raw : float = float(max_hp) * battle_max_hp_percent_per_turn
	var dmg : int = int(ceil(raw))

	if dmg < 1:
		dmg = 1
	if dmg > actor.current_hp:
		dmg = actor.current_hp

	return dmg


func get_field_dot_damage(actor : ActorData) -> int:
	if actor == null:
		return 0

	var max_hp : int = actor.get_max_hp()
	var raw : float = float(max_hp) * field_max_hp_percent_per_step
	var dmg : int = int(ceil(raw))

	if dmg < 1:
		dmg = 1
	if dmg > actor.current_hp:
		dmg = actor.current_hp

	return dmg

func _apply_stat_decrease(actor : ActorData) -> void:
	if _stats_applied:
		return

	var magnitude : float = abs(stat_percent_decrease)
	if magnitude <= 0.0:
		return

	var delta : float = -magnitude

	actor.set_stat_modifier(ActorData.STAT_STRENGTH, _SOURCE_KEY, 0, delta)
	actor.set_stat_modifier(ActorData.STAT_STAMINA, _SOURCE_KEY, 0, delta)
	actor.set_stat_modifier(ActorData.STAT_AGILITY, _SOURCE_KEY, 0, delta)
	actor.set_stat_modifier(ActorData.STAT_MAGIC, _SOURCE_KEY, 0, delta)
	actor.set_stat_modifier(ActorData.STAT_ATK_VALUE, _SOURCE_KEY, 0, delta)
	actor.set_stat_modifier(ActorData.STAT_DEF_VALUE, _SOURCE_KEY, 0, delta)

	actor.clamp_vitals()
	_stats_applied = true

func _remove_stat_decrease(actor : ActorData) -> void:
	if not _stats_applied:
		return

	actor.remove_stat_modifier(ActorData.STAT_STRENGTH, _SOURCE_KEY)
	actor.remove_stat_modifier(ActorData.STAT_STAMINA, _SOURCE_KEY)
	actor.remove_stat_modifier(ActorData.STAT_AGILITY, _SOURCE_KEY)
	actor.remove_stat_modifier(ActorData.STAT_MAGIC, _SOURCE_KEY)
	actor.remove_stat_modifier(ActorData.STAT_ATK_VALUE, _SOURCE_KEY)
	actor.remove_stat_modifier(ActorData.STAT_DEF_VALUE, _SOURCE_KEY)

	actor.clamp_vitals()
	_stats_applied = false
func on_turn_start_tick(status_system : StatusSystem) -> bool:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return false
	if actor.current_hp <= 0:
		return false

	# One tick per battler turn id
	var system_id : int = 0
	var turn_id : int = -1
	if status_system != null:
		system_id = int(status_system.get_instance_id())
		turn_id = status_system.current_turn_id

	# New StatusSystem instance, reset guard
	if system_id != _last_tick_status_system_id:
		_last_tick_status_system_id = system_id
		_last_tick_turn_id = -1

	# Already ticked for this battler turn
	if turn_id == _last_tick_turn_id:
		return false

	_last_tick_turn_id = turn_id

	var dmg : int = get_battle_dot_damage(actor)
	if dmg <= 0:
		return false

	actor.current_hp = clampi(actor.current_hp - dmg, 0, actor.get_max_hp())

	var target_battler : Battler = null
	if status_system != null:
		target_battler = status_system.get_battler_for_actor(actor)

	if status_system != null and status_system.battle_scene != null:
		var bs : BattleScene = status_system.battle_scene

		var name_text : String = actor.get_display_name()
		if name_text == "":
			name_text = "Someone"

		if bs.battle_notify_ui != null:
			var actions : Array[Callable] = []
			if target_battler != null and bs.battle_vfx != null:
				actions.append(Callable(bs.battle_vfx, "pop_text_poison").bind(target_battler, dmg))
			bs.battle_notify_ui.queue_notification(name_text + " suffers poison damage.", actions)

	if status_system != null and target_battler != null:
		var dmg_ctx : Dictionary = {
			"amount": dmg,
			"is_dot": true,
			"is_poison": true,
			"kind": "poison",
			"effect_context": null
		}
		status_system.on_receive_damage(target_battler, null, null, dmg_ctx)

	return true
