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


# -------------------------------------------------------------------
# Core CRUD
# -------------------------------------------------------------------
func add_status(receiver : Battler, effect : StatusEffect, caster : Battler = null) -> void:
	if receiver == null:
		return
	if effect == null:
		return
	if receiver.actor_data == null:
		return

	effect.caster = caster
	effect.receiver = receiver

	if receiver.actor_data.status_effects == null:
		receiver.actor_data.status_effects = []

	receiver.actor_data.status_effects.append(effect)
	effect.on_apply(self)


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
func on_turn_start(acting : Battler) -> void:
	if acting == null:
		return

	# Important: expiry can remove statuses from OTHER battlers (Defended),
	# so we iterate over all battlers in the battle.
	var battlers : Array[Battler] = _get_all_battlers()
	for bat in battlers:
		_remove_expiring_statuses_for_turn_start(acting, bat)

##Removes status effects that only last one turn
func _remove_expiring_statuses_for_turn_start(acting : Battler, _owner : Battler) -> void:
	if _owner == null:
		return
	if _owner.actor_data == null:
		return
	if _owner.actor_data.status_effects == null:
		return

	# Iterate backwards so removals are safe.
	for i in range(_owner.actor_data.status_effects.size() - 1, -1, -1):
		var s : StatusEffect = _owner.actor_data.status_effects[i]
		if s == null:
			_owner.actor_data.status_effects.remove_at(i)
			continue

		if s.expire_timing == StatusEffect.ExpireTiming.TURN_START_OF_BATTLER and s.expire_on_battler == acting:
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

	# Let statuses on the original target attempt to redirect.
	for s in original_target.actor_data.status_effects:
		if s == null:
			continue
		var redirected : Battler = s.redirect_incoming_target(attacker, action, original_target)
		if redirected != null:
			return redirected

	return original_target


func modify_incoming_physical_damage(attacker : Battler, action : BattleAction, original_target : Battler, final_target : Battler, damage : int) -> int:
	if final_target == null:
		return damage
	if final_target.actor_data == null:
		return damage
	if final_target.actor_data.status_effects == null:
		return damage

	var out_damage : int = damage
	for s in final_target.actor_data.status_effects:
		if s == null:
			continue
		out_damage = s.modify_incoming_physical_damage(attacker, action, original_target, final_target, out_damage)

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
