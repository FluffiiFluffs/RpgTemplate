class_name Effect
extends Resource
## Base class for item and skill effects.
## Effects are pure logic. UI feedback belongs to caller code.

enum Scope { FIELD_ONLY, BATTLE_ONLY, ALL }
@export var scope : Scope = Scope.ALL


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if ctx == null:
		return false
	if target == null:
		return false

	if scope == Scope.FIELD_ONLY:
		if ctx.mode == EffectContext.Mode.BATTLE:
			return false

	if scope == Scope.BATTLE_ONLY:
		if ctx.mode == EffectContext.Mode.FIELD:
			return false

	return true


## Returns true if something changed.
func apply(ctx : EffectContext, target : ActorData) -> bool:
	return false


func can_apply_to_battler(ctx : EffectContext, target : Battler) -> bool:
	if ctx == null:
		return false
	if target == null:
		return false
	ctx.current_target_battler = target
	return can_apply(ctx, target.actor_data)


func apply_to_battler(ctx : EffectContext, target : Battler) -> bool:
	if ctx == null:
		return false
	if target == null:
		return false
	ctx.current_target_battler = target
	return apply(ctx, target.actor_data)


## Compatibility wrappers so your current field menu code keeps working.
func can_use_on_member(member : PartyMemberData) -> bool:
	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.FIELD
	return can_apply(ctx, member)


func apply_to_member(member : PartyMemberData) -> bool:
	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.FIELD
	return apply(ctx, member)
