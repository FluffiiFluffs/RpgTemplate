class_name StatusEffectConfuse
extends StatusEffect

@export_category("Confuse Tuning")
@export_range(1, 99, 1) var duration_turns : int = 3
@export_range(0.0, 1.0, 0.01) var break_chance_on_damage : float = 0.5

var _turns_remaining : int = 3
var _last_forced_turn_id : int = -1

const _SKILL_ACTION_PATH : String = "res://battle/actions/skill/battleaction_skill.tres"


func _init() -> void:
	kind = StatusKind.AILMENT
	scope = Scope.BATTLE_ONLY

	exclusive_group_id = &"control"
	# Sleep must overwrite Confuse, and Stun must overwrite everything in control.
	# Sleep is currently rank 10, Stun is currently rank 1000.
	exclusive_rank = 9

	remove_on_death = true
	expire_timing = ExpireTiming.NONE

	_turns_remaining = duration_turns


func blocks_turn(_status_system : StatusSystem, _battler : Battler) -> bool:
	return false


func blocks_command_selection(_status_system : StatusSystem, _battler : Battler) -> bool:
	return true


func get_forced_action_use(status_system : StatusSystem, battler : Battler) -> ActionUse:
	if status_system == null:
		return null
	if battler == null:
		return null
	if battler.actor_data == null:
		return null
	if battler.actor_data.current_hp <= 0:
		return null

	var actor : ActorData = get_receiver_actor()
	if actor == null or battler.actor_data != actor:
		return null

	var turn_id : int = status_system.current_turn_id
	if turn_id == _last_forced_turn_id:
		return null
	_last_forced_turn_id = turn_id

	if _turns_remaining <= 0:
		status_system.remove_status(battler, self)
		return null

	var use : ActionUse = _build_random_action_use(status_system, battler)
	if use == null:
		return null

	_turns_remaining -= 1
	if _turns_remaining <= 0:
		status_system.remove_status(battler, self)

	return use


func _build_random_action_use(status_system : StatusSystem, battler : Battler) -> ActionUse:
	var actor : ActorData = battler.actor_data
	if actor == null:
		return null

	var choices : Array[Dictionary] = []

	# Normal attack and defend from BattleActions
	var actions_res : BattleActions = actor.battle_actions
	if actions_res != null and actions_res.battle_actions != null:
		for a in actions_res.battle_actions:
			if a == null:
				continue
			if a.type == BattleAction.ActionType.NORMAL_ATTACK or a.type == BattleAction.ActionType.DEFEND:
				choices.append({"kind": "action", "action": a})

	# All usable skills (no items, no run)
	if actor.skills != null:
		for s in actor.skills:
			if s == null:
				continue
			if s.scope == Skill.UseScope.FIELD_ONLY:
				continue
			if not s.can_pay_cost(actor):
				continue
			choices.append({"kind": "skill", "skill": s})

	# Fallback: normal attack if nothing else exists
	if choices.is_empty():
		var fallback_action : BattleAction = _find_first_action_of_type(actor, BattleAction.ActionType.NORMAL_ATTACK)
		if fallback_action == null:
			return null
		var fallback_targets : Array[Battler] = _choose_targets_for_battle_action(status_system, battler, fallback_action)
		return ActionUse.new(battler, fallback_action, fallback_targets, {})

	var pick : Dictionary = choices[randi_range(0, choices.size() - 1)]

	if pick.has("kind") and String(pick["kind"]) == "skill":
		var skill : Skill = pick["skill"] as Skill
		if skill == null:
			return null

		var skill_action : BattleAction = _get_skill_battle_action(actor)
		var targets : Array[Battler] = _choose_targets_for_skill(status_system, battler, skill)

		var data : Dictionary = {"skill": skill}
		return ActionUse.new(battler, skill_action, targets, data)

	var action : BattleAction = pick["action"] as BattleAction
	if action == null:
		return null

	var targets2 : Array[Battler] = _choose_targets_for_battle_action(status_system, battler, action)
	return ActionUse.new(battler, action, targets2, {})


func _find_first_action_of_type(actor : ActorData, t : int) -> BattleAction:
	if actor == null:
		return null
	if actor.battle_actions == null:
		return null
	if actor.battle_actions.battle_actions == null:
		return null

	for a in actor.battle_actions.battle_actions:
		if a == null:
			continue
		if a.type == t:
			return a

	return null


func _get_skill_battle_action(actor : ActorData) -> BattleAction:
	# Prefer an authored BattleActionSkill in the actor's BattleActions list
	if actor != null and actor.battle_actions != null and actor.battle_actions.battle_actions != null:
		for a in actor.battle_actions.battle_actions:
			if a == null:
				continue
			if a is BattleActionSkill:
				return a

	# Fall back to shared resource
	var loaded = load(_SKILL_ACTION_PATH)
	if loaded is BattleAction:
		return loaded as BattleAction

	# Final fallback
	return BattleActionSkill.new()


func _get_all_alive_battlers(status_system : StatusSystem) -> Array[Battler]:
	var out : Array[Battler] = []
	if status_system == null:
		return out
	if status_system.battle_scene == null:
		return out
	if status_system.battle_scene.battlers == null:
		return out

	for n in status_system.battle_scene.battlers.get_children():
		if n is Battler:
			var b : Battler = n as Battler
			if b.actor_data == null:
				continue
			if b.actor_data.current_hp <= 0:
				continue
			out.append(b)

	return out


func _choose_targets_for_battle_action(status_system : StatusSystem, user : Battler, action : BattleAction) -> Array[Battler]:
	if user == null or action == null:
		return []

	if action.target_shape == BattleAction.TargetShape.NONE:
		return []
	if action.target_shape == BattleAction.TargetShape.SELF:
		return [user]

	var alive : Array[Battler] = _get_all_alive_battlers(status_system)
	if alive.is_empty():
		return []

	var anchor : Battler = alive[randi_range(0, alive.size() - 1)]

	if action.target_shape == BattleAction.TargetShape.SINGLE:
		return [anchor]

	if action.target_shape == BattleAction.TargetShape.ALL:
		var out : Array[Battler] = []
		for b in alive:
			if b == null:
				continue
			if b.faction == anchor.faction:
				out.append(b)
		return out

	return []


func _choose_targets_for_skill(status_system : StatusSystem, user : Battler, skill : Skill) -> Array[Battler]:
	if user == null or skill == null:
		return []

	if skill.target_shape == Skill.TargetShape.NONE:
		return []
	if skill.target_shape == Skill.TargetShape.SELF:
		return [user]

	var alive : Array[Battler] = _get_all_alive_battlers(status_system)
	if alive.is_empty():
		return []

	var anchor : Battler = alive[randi_range(0, alive.size() - 1)]

	if skill.target_shape == Skill.TargetShape.SINGLE:
		return [anchor]

	if skill.target_shape == Skill.TargetShape.ALL:
		var out : Array[Battler] = []
		for b in alive:
			if b == null:
				continue
			if b.faction == anchor.faction:
				out.append(b)
		return out

	return []


static func try_break_on_damage(status_system : StatusSystem, target_battler : Battler, ctx : EffectContext = null) -> bool:
	if status_system == null:
		return false
	if target_battler == null:
		return false

	var found : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectConfuse)
	if found == null:
		return false

	var confuse : StatusEffectConfuse = found as StatusEffectConfuse
	if confuse == null:
		return false

	var roll : float = randf()
	if roll >= confuse.break_chance_on_damage:
		return false

	status_system.remove_status(target_battler, confuse)

	if ctx != null:
		ctx.queue_battle_message("{target} snaps out of confusion.", target_battler)
	elif status_system.battle_scene != null and status_system.battle_scene.battle_notify_ui != null:
		var name_text : String = "Someone"
		if target_battler.actor_data != null and target_battler.actor_data.char_resource != null:
			name_text = target_battler.actor_data.char_resource.char_name
		status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " snaps out of confusion.")

	return true
