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
# Turn permission
# -------------------------------------------------------------------
func can_battler_act(battler : Battler) -> bool:
	if battler == null:
		return false
	if battler.actor_data == null:
		return false
	if battler.actor_data.current_hp <= 0:
		return false
	if battler.actor_data.status_effects == null:
		return true

	var snapshot : Array = battler.actor_data.status_effects.duplicate()
	var primary_control : StatusEffect = _get_primary_control_status(snapshot)

	if primary_control != null:
		if primary_control.blocks_turn(self, battler):
			return false

	for s in snapshot:
		if s == null:
			continue
		if s == primary_control:
			continue
		if s.blocks_turn(self, battler):
			return false

	return true


func can_battler_select_commands(battler : Battler) -> bool:
	if battler == null:
		return false
	if battler.actor_data == null:
		return false
	if battler.actor_data.current_hp <= 0:
		return false
	if battler.actor_data.status_effects == null:
		return true

	var snapshot : Array = battler.actor_data.status_effects.duplicate()
	var primary_control : StatusEffect = _get_primary_control_status(snapshot)

	if primary_control != null:
		if primary_control.blocks_command_selection(self, battler):
			return false

	for s in snapshot:
		if s == null:
			continue
		if s == primary_control:
			continue
		if s.blocks_command_selection(self, battler):
			return false

	return true


func get_forced_action_use(battler : Battler) -> ActionUse:
	if battler == null:
		return null
	if battler.actor_data == null:
		return null
	if battler.actor_data.current_hp <= 0:
		return null
	if battler.actor_data.status_effects == null:
		return null

	var snapshot : Array = battler.actor_data.status_effects.duplicate()

	var best_use : ActionUse = null
	var best_rank : int = -2147483648
	var best_is_control : bool = false

	for s in snapshot:
		if s == null:
			continue

		var use : ActionUse = s.get_forced_action_use(self, battler)
		if use == null:
			continue

		var is_control : bool = s.exclusive_group_id == &"control"
		if best_use == null:
			best_use = use
			best_rank = s.exclusive_rank
			best_is_control = is_control
			continue

		if best_is_control and not is_control:
			continue

		if is_control and not best_is_control:
			best_use = use
			best_rank = s.exclusive_rank
			best_is_control = is_control
			continue

		if s.exclusive_rank > best_rank:
			best_use = use
			best_rank = s.exclusive_rank
			best_is_control = is_control

	return best_use
	
	
	
func get_turn_directive(battler : Battler) -> Dictionary:
	var out : Dictionary = {
		"can_select_commands": true,
		"can_execute_action": true,
		"forced_action_use": null,
		"skip_reason": ""
	}

	if battler == null:
		out["can_select_commands"] = false
		out["can_execute_action"] = false
		out["skip_reason"] = "null_battler"
		return out

	if battler.actor_data == null:
		out["can_select_commands"] = false
		out["can_execute_action"] = false
		out["skip_reason"] = "null_actor"
		return out

	if battler.actor_data.current_hp <= 0:
		out["can_select_commands"] = false
		out["can_execute_action"] = false
		out["skip_reason"] = "dead"
		return out

	# Hard permission gate for the turn
	if not can_battler_act(battler):
		out["can_select_commands"] = false
		out["can_execute_action"] = false
		out["skip_reason"] = "blocked_turn"
		return out

	# Forced action decision
	var forced : ActionUse = get_forced_action_use(battler)
	if forced != null:
		out["forced_action_use"] = forced
		out["can_select_commands"] = false
		out["can_execute_action"] = true
		out["skip_reason"] = "forced_action"
		return out

	# Command selection permission
	if not can_battler_select_commands(battler):
		out["can_select_commands"] = false
		out["skip_reason"] = "blocked_command_selection"

	return out


func _get_primary_control_status(statuses : Array) -> StatusEffect:
	var best : StatusEffect = null
	var best_rank : int = -2147483648

	for s in statuses:
		if s == null:
			continue
		if s.exclusive_group_id != &"control":
			continue
		if s.exclusive_rank > best_rank:
			best_rank = s.exclusive_rank
			best = s

	return best




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

	var runtime_effect : StatusEffect = effect
	if runtime_effect.resource_path != "":
		runtime_effect = runtime_effect.duplicate(true) as StatusEffect
		runtime_effect.reset_runtime_state()

	runtime_effect.bind_battle_context(receiver_actor, caster_actor)

	if receiver.actor_data.status_effects == null:
		receiver.actor_data.status_effects = []

	receiver.actor_data.status_effects.append(runtime_effect)
	runtime_effect.on_apply(self)


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

	var incoming_rank : int = effect.exclusive_rank
	var allow_equal_rank_replace : bool = group_id == &"control"

	if incoming_rank < highest_rank:
		result["outcome"] = AddStatusOutcome.BLOCKED
		result["blocked_by"] = highest_status
		return result

	if incoming_rank == highest_rank:
		if not allow_equal_rank_replace:
			result["outcome"] = AddStatusOutcome.BLOCKED
			result["blocked_by"] = highest_status
			return result

		# Equal rank in the control group
		# Block only when the same status script is already present
		var same_script_status : StatusEffect = null
		for s in in_group:
			if s == null:
				continue
			if s.get_script() == effect.get_script():
				same_script_status = s
				break

		if same_script_status != null:
			result["outcome"] = AddStatusOutcome.BLOCKED
			result["blocked_by"] = same_script_status
			return result

		# Tie and different script, replace all existing in the group
		for s in in_group:
			if s == null:
				continue
			result["removed"].append(s)
			remove_status(receiver, s)

		_add_status_unchecked(receiver, effect, caster)
		result["outcome"] = AddStatusOutcome.REPLACED
		return result

	# incoming_rank > highest_rank
	for s in in_group:
		if s == null:
			continue
		result["removed"].append(s)
		remove_status(receiver, s)

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
		var snapshot : Array = acting.actor_data.status_effects.duplicate()

		for s in snapshot:
			if s == null:
				continue
			if not acting.actor_data.status_effects.has(s):
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

func on_action_selected(battler : Battler, use : ActionUse) -> bool:
	if battler == null:
		return false
	if use == null:
		return false
	if battler.actor_data == null:
		return false
	if battler.actor_data.status_effects == null:
		return false

	var snapshot : Array = battler.actor_data.status_effects.duplicate()
	var primary_control : StatusEffect = _get_primary_control_status(snapshot)

	if primary_control != null:
		if primary_control.on_action_selected(self, battler, use):
			return true

	for s in snapshot:
		if s == null:
			continue
		if s == primary_control:
			continue
		if s.on_action_selected(self, battler, use):
			return true

	return false


func on_action_start(battler : Battler, use : ActionUse) -> void:
	if battler == null:
		return
	if use == null:
		return
	if battler.actor_data == null:
		return
	if battler.actor_data.status_effects == null:
		return

	var snapshot : Array = battler.actor_data.status_effects.duplicate()
	var primary_control : StatusEffect = _get_primary_control_status(snapshot)

	if primary_control != null:
		if battler.actor_data.status_effects.has(primary_control):
			primary_control.on_action_start(self, battler, use)

	for s in snapshot:
		if s == null:
			continue
		if s == primary_control:
			continue
		if not battler.actor_data.status_effects.has(s):
			continue
		s.on_action_start(self, battler, use)


func on_action_end(battler : Battler, use : ActionUse) -> void:
	if battler == null:
		return
	if use == null:
		return
	if battler.actor_data == null:
		return
	if battler.actor_data.status_effects == null:
		return

	var snapshot : Array = battler.actor_data.status_effects.duplicate()
	var primary_control : StatusEffect = _get_primary_control_status(snapshot)

	if primary_control != null:
		if battler.actor_data.status_effects.has(primary_control):
			primary_control.on_action_end(self, battler, use)

	for s in snapshot:
		if s == null:
			continue
		if s == primary_control:
			continue
		if not battler.actor_data.status_effects.has(s):
			continue
		s.on_action_end(self, battler, use)



func get_post_action_bonus_use(original_use : ActionUse) -> ActionUse:
	if original_use == null:
		return null

	var user : Battler = original_use.user
	if user == null:
		return null
	if user.actor_data == null:
		return null
	if user.actor_data.status_effects == null:
		return null

	var snapshot : Array = user.actor_data.status_effects.duplicate()
	for s in snapshot:
		if s == null:
			continue
		var bonus : ActionUse = s.get_post_action_bonus_use(self, original_use)
		if bonus != null:
			return bonus

	return null


func on_receive_damage(defender : Battler, attacker : Battler, action_use : ActionUse, dmg_ctx : Dictionary) -> void:
	if defender == null:
		return
	if defender.actor_data == null:
		return
	if defender.actor_data.status_effects == null:
		return

	var snapshot : Array = defender.actor_data.status_effects.duplicate()
	for s in snapshot:
		if s == null:
			continue
		if not defender.actor_data.status_effects.has(s):
			continue
		s.on_receive_damage(self, defender, attacker, action_use, dmg_ctx)

func set_defend_link(defender : Battler, protected : Battler) -> bool:
	if defender == null or protected == null:
		return false
	if defender.actor_data == null or protected.actor_data == null:
		return false

	# Clear existing defend link on the defender (also removes its linked Defended via StatusEffectDefending.on_remove)
	remove_status_by_class(defender, StatusEffectDefending)

	# If the protected battler is already linked to someone else, clear that link too
	var existing_defended : StatusEffect = StatusSystem.find_status(protected, StatusEffectDefended)
	if existing_defended != null:
		var defended_status : StatusEffectDefended = existing_defended as StatusEffectDefended

		var old_defender_battler : Battler = null
		if defended_status.defender_actor != null:
			old_defender_battler = get_battler_for_actor(defended_status.defender_actor)

		remove_status(protected, defended_status)

		if old_defender_battler != null and old_defender_battler != defender:
			remove_status_by_class(old_defender_battler, StatusEffectDefending)

	# Create fresh per application instances
	var defending : StatusEffectDefending = Registry.instantiate_status(&"statusdefending") as StatusEffectDefending
	defending.protected_actor = protected.actor_data
	add_status(defender, defending, defender)

	var defended : StatusEffectDefended = Registry.instantiate_status(&"statusdefended") as StatusEffectDefended
	defended.defender_actor = defender.actor_data
	add_status(protected, defended, defender)

	return true




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
func _clear_battle_only_statuses() -> void:
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



func _detach_persistent_status_battle_refs() -> void:
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



func _remove_statuses_on_death(dead_battler : Battler) -> void:
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



func should_force_physical_hit(defender : Battler) -> bool:
	if defender == null:
		return false
	if defender.actor_data == null:
		return false
	if defender.actor_data.status_effects == null:
		return false

	for s in defender.actor_data.status_effects:
		if s == null:
			continue
		if s.forces_physical_hit(self, defender):
			return true

	return false


# -------------------------------------------------------------------
# Cleanup entry points

func on_death(dead_battler : Battler) -> void:
	_remove_statuses_on_death(dead_battler)


func on_battle_end() -> void:
	_clear_battle_only_statuses()
	_detach_persistent_status_battle_refs()


func on_turn_end(_battler : Battler) -> void:
	# Reserved for future end of turn expirations and end of turn ticks.
	pass
