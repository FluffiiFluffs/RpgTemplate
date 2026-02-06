class_name StatusEffectHaste
extends StatusEffect

## [Haste]
## Raises the receiver's agility via ActorData stat modifier aggregator.
## Stack levels are represented as ranks (1 to 3) via exclusive_rank.
## Rank values represent the total increase, not an additive delta.

@export_range(1, 3, 1) var stack_level : int = 1

## Total agility increase for the current stack level.
## This value is derived from stack_level via _sync_from_stack().
@export_range(0.0, 1.0, 0.0001) var agility_percent_increase_total : float = 0.15

var _stats_applied : bool = false
const _BONUS_NONE : int = 0
const _BONUS_OFFENSIVE : int = 1
const _BONUS_BENEFICIAL : int = 2
const _STAT_KEY : StringName = ActorData.STAT_AGILITY
const _SOURCE_KEY : StringName = &"status_haste"




func _init() -> void:
	kind = StatusKind.ENHANCEMENT
	scope = Scope.BATTLE_ONLY

	exclusive_group_id = &"haste"
	exclusive_rank = 1

	remove_on_death = true
	expire_timing = ExpireTiming.NONE

	_sync_from_stack()


## Configure this instance for a specific stack level.
## Call this immediately after StatusEffectHaste.new() and before the status is added.
func configure(level : int) -> void:
	stack_level = clampi(level, 1, 3)
	exclusive_rank = stack_level
	_sync_from_stack()


func _sync_from_stack() -> void:
	agility_percent_increase_total = get_percent_for_stack(stack_level)


static func get_percent_for_stack(level : int) -> float:
	if level <= 1:
		return 0.15
	if level == 2:
		return 0.20
	return 0.25


func is_max_stack() -> bool:
	return stack_level >= 3


func on_apply(_status_system : StatusSystem) -> void:
	# Keep rank and tuning synced in case this Resource was edited in the inspector
	stack_level = clampi(stack_level, 1, 3)
	exclusive_rank = stack_level
	_sync_from_stack()

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_apply_agility_increase(actor)


func on_remove(_status_system : StatusSystem) -> void:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return

	_remove_agility_increase(actor)

func _apply_agility_increase(actor : ActorData) -> void:
	if _stats_applied:
		return

	var magnitude : float = abs(agility_percent_increase_total)
	if magnitude <= 0.0:
		return

	actor.set_stat_modifier(_STAT_KEY, _SOURCE_KEY, 0, magnitude)
	actor.clamp_vitals()
	_stats_applied = true

func _remove_agility_increase(actor : ActorData) -> void:
	if not _stats_applied:
		return

	actor.remove_stat_modifier(_STAT_KEY, _SOURCE_KEY)
	actor.clamp_vitals()
	_stats_applied = false


func get_post_action_bonus_use(status_system : StatusSystem, original_use : ActionUse) -> ActionUse:
	if status_system == null:
		return null
	if original_use == null:
		return null

	if not is_max_stack():
		return null

	var user : Battler = original_use.user
	if user == null:
		return null
	if user.actor_data == null:
		return null
	if user.actor_data.current_hp <= 0:
		return null

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return null
	if user.actor_data != actor:
		return null

	if original_use.action_type == BattleAction.ActionType.USE_ITEM:
		return null

	if original_use.targets == null or original_use.targets.size() != 1:
		return null

	var anchor_target : Battler = original_use.first_target()
	if anchor_target == null:
		return null

	var qualifies_offensive : bool = false
	var qualifies_beneficial : bool = false

	if original_use.action_type == BattleAction.ActionType.NORMAL_ATTACK:
		qualifies_offensive = true
	elif original_use.action_type == BattleAction.ActionType.USE_SKILL:
		if original_use.data == null:
			return null
		if not original_use.data.has("skill"):
			return null
		var skill : Skill = original_use.data["skill"] as Skill
		if skill == null:
			return null
		if skill.target_shape != Skill.TargetShape.SINGLE:
			return null
	
		match skill.intent:
			Skill.Intent.BENEFICIAL:
				qualifies_beneficial = true
			Skill.Intent.HARMFUL:
				qualifies_offensive = true
			Skill.Intent.MIXED:
				# Treat MIXED as qualifying for a bonus use, but retarget according to the skill’s authored TargetSide.
				qualifies_offensive = true
			Skill.Intent.UTILITY:
				return null

	else:
		return null

	if not qualifies_offensive and not qualifies_beneficial:
		return null

	var bonus_target : Battler = null
	if qualifies_offensive:
		if original_use.action_type == BattleAction.ActionType.NORMAL_ATTACK:
			bonus_target = Targeting.retarget_if_dead(
				user,
				status_system.battle_scene,
				anchor_target,
				Targeting.RetargetPolicy.OTHER_FACTION_THAN_USER
			)
		else:
			var skill : Skill = original_use.data["skill"] as Skill
			bonus_target = _pick_bonus_target_for_skill(status_system, user, skill, anchor_target)

		if bonus_target == null:
			return null


	elif qualifies_beneficial:
		bonus_target = Targeting.pick_random_living_ally(user, status_system.battle_scene, true)
		if bonus_target == null:
			return null

	var bonus_data : Dictionary = {}
	if original_use.data != null:
		bonus_data = original_use.data.duplicate(true)

	if original_use.action_type == BattleAction.ActionType.USE_SKILL:
		bonus_data["free_cost"] = true

	return ActionUse.new(user, original_use.action, [bonus_target], bonus_data)


func _retarget_policy_for_skill(skill : Skill) -> int:
	if skill == null:
		return Targeting.RetargetPolicy.NONE

	if skill.target_side == Skill.TargetSide.SAME_FACTION:
		return Targeting.RetargetPolicy.SAME_FACTION_AS_USER

	if skill.target_side == Skill.TargetSide.OTHER_FACTION:
		return Targeting.RetargetPolicy.OTHER_FACTION_THAN_USER

	# Skill.TargetSide.ANY_FACTION
	# Preserve the original choice “side” by staying in the original target’s faction.
	return Targeting.RetargetPolicy.SAME_FACTION_AS_TARGET


func _pick_bonus_target_for_skill(status_system : StatusSystem, user : Battler, skill : Skill, anchor_target : Battler) -> Battler:
	if status_system == null:
		return null
	if user == null:
		return null
	if skill == null:
		return null
	if anchor_target == null:
		return null
	if status_system.battle_scene == null:
		return null

	var policy : int = _retarget_policy_for_skill(skill)
	return Targeting.retarget_if_dead(
		user,
		status_system.battle_scene,
		anchor_target,
		policy,
		true
	)
