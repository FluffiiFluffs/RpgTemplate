## status_system.gd
class_name StatusSystem
extends Node
## Central manager for applying and resolving StatusEffects.
##
## Assumptions (align these with your project):
## - Each Battler has: battler.actor_data.status_effects : Array[StatusEffect]
## - BattleScene has a node containing battlers. In your project this is typically:
##     battle_scene.battlers
## - StatusEffect provides:
##     expire_timing, expire_on_battler
##     on_apply(), on_remove()
##     redirect_incoming_target()
##     modify_incoming_physical_damage()

var battle_scene : BattleScene = null

# Set by TurnManager before calling on_turn_start()
var current_turn_id : int = 0



enum AddStatusOutcome { APPLIED, BLOCKED, REPLACED }



# -------------------------------------------------------------------
# Core CRUD
# -------------------------------------------------------------------
func _add_status_unchecked(receiver : Battler, effect : StatusEffect, caster : Battler = null) -> void:
	if receiver == null:
		return
	if effect == null:
		return
	if receiver.actor_data == null:
		return

	var receiver_actor : ActorData = receiver.actor_data
	var caster_actor : ActorData = null
	if caster != null:
		caster_actor = caster.actor_data

	effect.bind_battle_context(receiver_actor, caster_actor)

	if receiver.actor_data.status_effects == null:
		receiver.actor_data.status_effects = []

	receiver.actor_data.status_effects.append(effect)
	effect.on_apply(self)



func try_add_status(receiver : Battler, effect : StatusEffect, caster : Battler = null) -> Dictionary:
	var result : Dictionary = {
		"outcome": AddStatusOutcome.APPLIED,
		"blocked_by": null,
		"removed": [],
	}

	if receiver == null:
		return result
	if effect == null:
		return result
	if receiver.actor_data == null:
		return result

	if receiver.actor_data.status_effects == null:
		receiver.actor_data.status_effects = []

	var group_id : StringName = effect.exclusive_group_id
	if group_id == &"":
		_add_status_unchecked(receiver, effect, caster)
		return result

	var in_group : Array[StatusEffect] = []
	var highest_rank : int = -2147483648
	var highest_status : StatusEffect = null

	for s in receiver.actor_data.status_effects:
		if s == null:
			continue
		if s.exclusive_group_id != group_id:
			continue

		in_group.append(s)
		if s.exclusive_rank > highest_rank:
			highest_rank = s.exclusive_rank
			highest_status = s

	if in_group.size() == 0:
		_add_status_unchecked(receiver, effect, caster)
		return result

	# Existing status in group found, decide block vs replace
	if effect.exclusive_rank <= highest_rank:
		result["outcome"] = AddStatusOutcome.BLOCKED
		result["blocked_by"] = highest_status
		return result

	# New one is stronger, remove all existing in the group
	for s in in_group:
		if s == null:
			continue
		remove_status(receiver, s)
		result["removed"].append(s)

	_add_status_unchecked(receiver, effect, caster)
	result["outcome"] = AddStatusOutcome.REPLACED
	return result




func add_status(receiver : Battler, effect : StatusEffect, caster : Battler = null) -> void:
	try_add_status(receiver, effect, caster)



func remove_status(receiver : Battler, effect : StatusEffect) -> void:
	if receiver == null:
		return
	if effect == null:
		return
	if receiver.actor_data == null:
		return
	if receiver.actor_data.status_effects == null:
		return

	if receiver.actor_data.status_effects.has(effect):
		effect.on_remove(self)
		receiver.actor_data.status_effects.erase(effect)

##Finds status and removes it
func remove_status_by_class(receiver : Battler, status_class : Variant) -> void:
	var found : StatusEffect = find_status(receiver, status_class)
	if found != null:
		remove_status(receiver, found)

##Finds a status on a target
static func find_status(receiver : Battler, status_class : Variant) -> StatusEffect:
	if receiver == null:
		return null
	if receiver.actor_data == null:
		return null
	if receiver.actor_data.status_effects == null:
		return null

	for s in receiver.actor_data.status_effects:
		if s == null:
			continue
		if is_instance_of(s, status_class):
			return s
	return null


# -------------------------------------------------------------------
# Turn lifecycle (expiry)
# -------------------------------------------------------------------
##What to do with status effects on turn start
func on_turn_start(acting : Battler) -> bool:
	if acting == null:
		return false

	# Expire statuses that end at the start of this battler's turn
	var battlers : Array[Battler] = _get_all_battlers()
	for bat in battlers:
		_remove_expiring_statuses_for_turn_start(acting, bat)

	var did_tick : bool = false

	# Tick statuses owned by the acting battler
	if acting.actor_data != null and acting.actor_data.status_effects != null:
		for s in acting.actor_data.status_effects:
			if s == null:
				continue

			if s.on_turn_start_tick(self):
				did_tick = true

	# Only wait when BattleNotifyUI is actively displaying or has pending notifications
	if battle_scene != null and battle_scene.battle_notify_ui != null:
		var ui : BattleNotifyUI = battle_scene.battle_notify_ui
		if ui.notifying or not ui.notify_queue.is_empty():
			await battle_scene.notify_finished

	return did_tick


func _remove_expiring_statuses_for_turn_start(acting : Battler, _owner : Battler) -> void:
	if _owner == null:
		return
	if _owner.actor_data == null:
		return
	if _owner.actor_data.status_effects == null:
		return
	if acting == null:
		return
	if acting.actor_data == null:
		return

	var acting_actor : ActorData = acting.actor_data

	for i in range(_owner.actor_data.status_effects.size() - 1, -1, -1):
		var s : StatusEffect = _owner.actor_data.status_effects[i]
		if s == null:
			_owner.actor_data.status_effects.remove_at(i)
			continue

		if s.expire_timing == StatusEffect.ExpireTiming.TURN_START_OF_BATTLER:
			if s.expire_on_actor == acting_actor:
				s.on_remove(self)
				_owner.actor_data.status_effects.remove_at(i)



# -------------------------------------------------------------------
# Resolution helpers (Defend interception + mitigation)
# -------------------------------------------------------------------
func resolve_incoming_target(attacker : Battler, action : BattleAction, original_target : Battler) -> Battler:
	if original_target == null:
		return null
	if original_target.actor_data == null:
		return original_target
	if original_target.actor_data.status_effects == null:
		return original_target

	var attacker_actor : ActorData = null
	if attacker != null:
		attacker_actor = attacker.actor_data

	var original_actor : ActorData = original_target.actor_data

	for s in original_actor.status_effects:
		if s == null:
			continue

		var redirected_actor : ActorData = s.redirect_incoming_target(attacker_actor, action, original_actor)
		if redirected_actor != null:
			var redirected_battler : Battler = get_battler_for_actor(redirected_actor)
			if redirected_battler != null:
				return redirected_battler

	return original_target


func modify_incoming_physical_damage(attacker : Battler, action : BattleAction, original_target : Battler, final_target : Battler, damage : int) -> int:
	if final_target == null:
		return damage
	if final_target.actor_data == null:
		return damage
	if final_target.actor_data.status_effects == null:
		return damage

	var attacker_actor : ActorData = null
	if attacker != null:
		attacker_actor = attacker.actor_data

	var original_actor : ActorData = null
	if original_target != null:
		original_actor = original_target.actor_data

	var final_actor : ActorData = final_target.actor_data

	var out_damage : int = damage
	for s in final_actor.status_effects:
		if s == null:
			continue
		out_damage = s.modify_incoming_physical_damage(attacker_actor, action, original_actor, final_actor, out_damage)

	return out_damage

# -------------------------------------------------------------------
# Cleanup
# -------------------------------------------------------------------
func clear_battle_only_statuses() -> void:
	var battlers : Array[Battler] = _get_all_battlers()
	for bat in battlers:
		if bat == null:
			continue
		if bat.actor_data == null:
			continue
		if bat.actor_data.status_effects == null:
			continue

		for i in range(bat.actor_data.status_effects.size() - 1, -1, -1):
			var s : StatusEffect = bat.actor_data.status_effects[i]
			if s == null:
				bat.actor_data.status_effects.remove_at(i)
				continue
			if s.scope == StatusEffect.Scope.BATTLE_ONLY:
				s.on_remove(self)
				bat.actor_data.status_effects.remove_at(i)


##Gets all battlers
func _get_all_battlers() -> Array[Battler]:
	var out : Array[Battler] = []
	for child in battle_scene.battlers.get_children():
		if child is Battler:
			out.append(child)

	return out

func get_battler_for_actor(actor : ActorData) -> Battler:
	if actor == null:
		return null
	if battle_scene == null:
		return null
	if battle_scene.battlers == null:
		return null

	for child in battle_scene.battlers.get_children():
		if child is Battler:
			var b : Battler = child
			if b.actor_data == actor:
				return b

	return null



func detach_persistent_status_battle_refs() -> void:
	var battlers : Array[Battler] = _get_all_battlers()
	for bat in battlers:
		if bat == null:
			continue
		if bat.actor_data == null:
			continue
		if bat.actor_data.status_effects == null:
			continue

		for s in bat.actor_data.status_effects:
			if s == null:
				continue

			# Only statuses that can persist beyond battle need detaching
			if s.scope == StatusEffect.Scope.ALL or s.scope == StatusEffect.Scope.FIELD_ONLY:
				s.detach_battle_context()



func remove_statuses_on_death(dead_battler : Battler) -> void:
	if dead_battler == null:
		return
	if dead_battler.actor_data == null:
		return
	if dead_battler.actor_data.status_effects == null:
		return

	for i in range(dead_battler.actor_data.status_effects.size() - 1, -1, -1):
		var s : StatusEffect = dead_battler.actor_data.status_effects[i]
		if s == null:
			dead_battler.actor_data.status_effects.remove_at(i)
			continue

		if s.remove_on_death:
			s.on_remove(self)
			dead_battler.actor_data.status_effects.remove_at(i)
