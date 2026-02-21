class_name Effect
extends Resource
## Base Resource for a single gameplay effect used by Items and Skills.
## Callers provide an EffectContext that describes whether this is FIELD or BATTLE execution and
## optionally provides battle hooks (BattleScene, StatusSystem, current_target_battler, etc).
##
## Subclasses typically override can_apply() and apply().
## Return values are treated as "did this effect change anything on the target".

enum Scope { FIELD_ONLY, BATTLE_ONLY, ALL }

## Declares which runtime contexts this Effect is allowed to run in.
## Enforced in can_apply() via ctx.mode.
@export var scope : Scope = Scope.ALL


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	## Primary eligibility gate for this effect on a specific target.
	## Used by:
	##   Item.can_apply_to_target() for generic targetability checks.
	##   Effect subclasses via super.can_apply(ctx, target) as the first early exit gate.
	##   Battle target filtering via can_apply_to_battler().
	##
	## This function is expected to be side effect free.
	if ctx == null:
		return false
	if target == null:
		return false

	## Enforce author declared scope against the current execution mode.
	if scope == Scope.FIELD_ONLY:
		if ctx.mode == EffectContext.Mode.BATTLE:
			return false

	if scope == Scope.BATTLE_ONLY:
		if ctx.mode == EffectContext.Mode.FIELD:
			return false

	return true


## Executes the effect and returns true when the target state changed.
## Callers commonly use this to decide "no effect" messaging and item consumption.
##
## Subclasses should guard with can_apply(ctx, target) since many callers invoke apply directly.
func apply(_ctx : EffectContext, _target : ActorData) -> bool:
	return false


func can_apply_to_battler(ctx : EffectContext, target : Battler) -> bool:
	## Battle convenience wrapper for target validation during targeting and previews.
	## Sets ctx.current_target_battler so can_apply overrides can reference the Battler node.
	## Used by CommandController to filter valid battle targets for Skills and Items.
	if ctx == null:
		return false
	if target == null:
		return false
	ctx.current_target_battler = target
	return can_apply(ctx, target.actor_data)


func apply_to_battler(ctx : EffectContext, target : Battler) -> bool:
	## Battle convenience wrapper for execution.
	## Sets ctx.current_target_battler so apply overrides can spawn VFX on the Battler node.
	## Used by ActionResolver when executing Skills and Items in battle.
	if ctx == null:
		return false
	if target == null:
		return false
	ctx.current_target_battler = target
	return apply(ctx, target.actor_data)


## Field menu compatibility wrapper.
## Creates a FIELD context and delegates to can_apply().
## Used by GameMenu UI to decide which party members can be targeted by an inventory item.
func can_use_on_member(member : PartyMemberData) -> bool:
	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.FIELD
	return can_apply(ctx, member)


## Field menu compatibility wrapper.
## Creates a FIELD context and delegates to apply().
## Used by TopLevelStats when the player confirms an item target in the field menu.
func apply_to_member(member : PartyMemberData) -> bool:
	var ctx = EffectContext.new()
	ctx.mode = EffectContext.Mode.FIELD
	return apply(ctx, member)
