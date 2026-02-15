class_name StatusEffectConfuse
extends StatusEffect

@export_category("Confuse Tuning")
@export_range(1, 99, 1) var duration_turns : int = 3
@export_range(0.0, 1.0, 0.01) var break_chance_on_damage : float = 0.5

var _turns_remaining : int = 3
var _last_forced_turn_id : int = -1


func _init() -> void:
	kind = StatusKind.AILMENT
	scope = Scope.BATTLE_ONLY

	exclusive_group_id = &"control"
	# Sleep must overwrite Confuse, and Stun must overwrite everything in control.
	# Sleep is currently rank 10, Stun is currently rank 1000.
	exclusive_rank = 10

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

	# Always include the receiver's normal attack skill if it exists.
	# This keeps "attack" execution in the USE_SKILL pipeline.
	var normal_skill : Skill = actor.normal_attack_skill
	if normal_skill != null:
		if normal_skill.scope != Skill.UseScope.FIELD_ONLY and normal_skill.can_pay_cost(actor):
			choices.append({"kind": "skill", "skill": normal_skill})

	# Defend from BattleActions (kept as BattleAction)
	var actions_res : BattleActions = actor.battle_actions
	if actions_res != null and actions_res.battle_actions != null:
		for a in actions_res.battle_actions:
			if a == null:
				continue
			if a.type == BattleAction.ActionType.DEFEND:
				choices.append({"kind": "action", "action": a})

	# All usable skills (no items, no run). Avoid duplicating the normal attack skill.
	if actor.skills != null:
		for s in actor.skills:
			if s == null:
				continue
			if s == normal_skill:
				continue
			if s.scope == Skill.UseScope.FIELD_ONLY:
				continue
			if not s.can_pay_cost(actor):
				continue
			choices.append({"kind": "skill", "skill": s})

	# Fallback: if nothing is usable, do nothing.
	if choices.is_empty():
		return null

	var pick : Dictionary = choices[randi_range(0, choices.size() - 1)]

	if pick.has("kind") and String(pick["kind"]) == "skill":
		var skill : Skill = pick["skill"] as Skill
		if skill == null:
			return null

		var skill_action : BattleAction = status_system.battle_scene.BATTLEACTION_SKILL

		var targets : Array[Battler] = _choose_targets_for_skill(status_system, battler, skill)

		var use : ActionUse = ActionUse.new(battler, skill_action, targets, {})
		use.skill = skill
		return use

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


func _choose_targets_for_battle_action(status_system : StatusSystem, user : Battler, action : BattleAction) -> Array[Battler]:
	if user == null or action == null:
		return []

	if action.target_shape == BattleAction.TargetShape.NONE:
		return []
	if action.target_shape == BattleAction.TargetShape.SELF:
		return [user]

	var bs : BattleScene = null
	if status_system != null:
		bs = status_system.battle_scene

	var anchor : Battler = Targeting.pick_random_living_any(bs)
	if anchor == null:
		return []


	if action.target_shape == BattleAction.TargetShape.SINGLE:
		return [anchor]


	if action.target_shape == BattleAction.TargetShape.ALL:
		return Targeting.get_all_living_battlers_in_faction(bs, anchor.faction)


	return []



func _choose_targets_for_skill(status_system : StatusSystem, user : Battler, skill : Skill) -> Array[Battler]:
	if user == null or skill == null:
		return []

	if skill.target_shape == Skill.TargetShape.NONE:
		return []
	if skill.target_shape == Skill.TargetShape.SELF:
		return [user]

	var bs : BattleScene = null
	if status_system != null:
		bs = status_system.battle_scene

	var anchor : Battler = Targeting.pick_random_living_any(bs)
	if anchor == null:
		return []


	if skill.target_shape == Skill.TargetShape.SINGLE:
		return [anchor]

	if skill.target_shape == Skill.TargetShape.ALL:
		return Targeting.get_all_living_battlers_in_faction(bs, anchor.faction)


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
		if target_battler.actor_data != null:
			name_text = target_battler.actor_data.get_display_name()
		status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " snaps out of confusion.")

	return true


func on_receive_damage(status_system : StatusSystem, defender : Battler, _attacker : Battler, _action_use : ActionUse, dmg_ctx : Dictionary) -> void:
	if status_system == null:
		return
	if defender == null:
		return
	if defender.actor_data == null:
		return

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return
	if defender.actor_data != actor:
		return

	if dmg_ctx != null:
		if dmg_ctx.has("is_dot") and bool(dmg_ctx["is_dot"]):
			return
		if dmg_ctx.has("is_poison") and bool(dmg_ctx["is_poison"]):
			return
		if dmg_ctx.has("amount") and int(dmg_ctx["amount"]) <= 0:
			return

	if randf() >= break_chance_on_damage:
		return

	status_system.remove_status(defender, self)

	var ctx : EffectContext = null
	if dmg_ctx != null and dmg_ctx.has("effect_context"):
		ctx = dmg_ctx["effect_context"] as EffectContext

	if ctx != null:
		ctx.queue_battle_message("{target} snaps out of confusion.", defender)
	elif status_system.battle_scene != null and status_system.battle_scene.battle_notify_ui != null:
		var name_text : String = "Someone"
		if defender.actor_data != null:
			name_text = defender.actor_data.get_display_name()
		status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " snaps out of confusion.")
