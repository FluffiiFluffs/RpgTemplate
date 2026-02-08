class_name StatusEffectStun
extends StatusEffect


func _init() -> void:
	kind = StatusKind.AILMENT
	scope = Scope.BATTLE_ONLY

	# High rank so nothing overwrites stun in the control group.
	# Sleep is rank 10.
	exclusive_group_id = &"control"
	exclusive_rank = 10

	remove_on_death = true
	expire_timing = ExpireTiming.NONE


func on_turn_start_tick(status_system : StatusSystem) -> bool:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return false
	if actor.current_hp <= 0:
		return false
	if status_system == null:
		return false
	if status_system.battle_scene == null:
		return false
	if status_system.battle_scene.battle_notify_ui == null:
		return false

	var name_text : String = actor.get_display_name()
	if name_text == "":
		name_text = "Someone"


	status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " is stunned!")
	return false


func blocks_turn(status_system : StatusSystem, battler : Battler) -> bool:
	# Consume the stun on the owner's next turn.
	if status_system == null:
		return true
	if battler == null:
		return true
	if battler.actor_data == null:
		return true

	var actor : ActorData = get_receiver_actor()
	if actor != null and battler.actor_data != actor:
		return false

	status_system.remove_status(battler, self)
	return true


func blocks_command_selection(_status_system : StatusSystem, _battler : Battler) -> bool:
	return true
