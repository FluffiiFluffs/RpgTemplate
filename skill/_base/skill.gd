class_name Skill
extends Resource

## Authoring scope for where this skill is intended to be usable.
## The template does not currently enforce this automatically.
enum UseScope { FIELD_ONLY, BATTLE_ONLY, ALL }

## Target selection shape used by CommandController when entering targeting mode.
enum TargetShape {
	NONE,   ## No targeting step, action resolves immediately.
	SELF,   ## Targets the user battler only.
	SINGLE, ## Select one battler.
	ALL     ## Select an anchor battler then expand to all valid battlers.
}

## Determines which faction is considered valid during targeting.
enum TargetSide {
	SAME_FACTION,
	OTHER_FACTION,
	ANY_FACTION
}

## Hint for initial focus placement during targeting.
## Used by CommandController._focus_default_target.
enum DefaultTargetFocus {
	AUTO,
	SAME_FACTION,
	OTHER_FACTION
}
## High level intent classification for skill uses.
## This is authored explicitly per skill, no automatic inference.
enum Intent {
	UTILITY = 0,
	HARMFUL = 1,
	BENEFICIAL = 2,
	MIXED = 3
}




@export_group("Identity")
## Stable identifier for data lookups and save serialization.
@export var skill_id : StringName = &""
## Display name used by UI and message templates.
@export var name : String = ""
## UI description displayed in skill lists and on focus.
@export_multiline var description : String = ""
## UI icon for menus and skill buttons.
@export var icon : Texture2D = null

@export_group("Availability")
## Intended use context (field, battle, or both). Not currently enforced by callers.
@export var scope : UseScope = UseScope.ALL

@export_group("Costs")
## Resource cost paid by the user when the skill is executed.
@export var sp_cost : int = 0
## HP cost paid by the user when the skill is executed.
## can_pay_cost enforces current_hp must remain at least 1 after payment.
@export var hp_cost : int = 0

@export_group("Targeting")
## Targeting behavior used by CommandController during skill targeting.
@export var target_shape : TargetShape = TargetShape.SINGLE
@export var target_side : TargetSide = TargetSide.ANY_FACTION
## When false, CommandController excludes battlers with current_hp <= 0 from the valid target set.
@export var can_target_dead : bool = false
## Initial focus hint applied when opening targeting for this skill.
@export var default_target_focus : DefaultTargetFocus = DefaultTargetFocus.AUTO
## Gameplay classification for systems that need a stable notion of offensive vs beneficial.
@export var intent : Intent = Intent.UTILITY



@export_group("Effects")
## Default effect list. Used in field. In battle, used only when battle_effects is empty.
@export var effects : Array[Effect] = []
## Battle override effect list. Used in battle when non empty (replaces effects for battle execution and targeting).
@export var battle_effects : Array[Effect] = []

@export_group("Message")
## Used by ActionResolver and TextParser to build battle log text.
## Supported tokens include {user}, {targets}, {target}, {skill}.
@export_multiline var message_template : String = "{user} uses {skill}."


func get_effects_for_context(ctx : EffectContext) -> Array[Effect]:
	## Returns the effect list that should be used for this execution context.
	## Battle uses battle_effects when provided, otherwise falls back to effects.
	if ctx != null:
		if ctx.mode == EffectContext.Mode.BATTLE:
			if not battle_effects.is_empty():
				return battle_effects
	return effects


func can_pay_cost(user_actor : ActorData) -> bool:
	## Cost gate used by battle UI and battle execution.
	## Returns false when the user is dead, lacks SP, or paying HP cost would reduce HP to 0 or below.
	if user_actor == null:
		return false
	if user_actor.current_hp <= 0:
		return false
	if user_actor.current_sp < sp_cost:
		return false
	if user_actor.current_hp <= hp_cost:
		return false
	return true


func pay_cost(user_actor : ActorData) -> void:
	## Applies SP and HP costs to the user, then clamps vitals.
	## Callers typically validate can_pay_cost first.
	if user_actor == null:
		return
	user_actor.current_sp = user_actor.current_sp - sp_cost
	user_actor.current_hp = user_actor.current_hp - hp_cost
	user_actor.clamp_vitals()
