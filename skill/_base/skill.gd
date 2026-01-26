class_name Skill
extends Resource

enum UseScope { FIELD_ONLY, BATTLE_ONLY, ALL }

enum TargetShape {
	NONE,
	SELF,
	SINGLE,
	ALL
}

enum TargetSide {
	SAME_FACTION,
	OTHER_FACTION,
	ANY_FACTION
}

enum DefaultTargetFocus {
	AUTO,
	SAME_FACTION,
	OTHER_FACTION
}

@export_group("Identity")
@export var skill_id : StringName = &""
@export var name : String = ""
@export_multiline var description : String = ""
@export var icon : Texture2D = null

@export_group("Availability")
@export var scope : UseScope = UseScope.ALL

@export_group("Costs")
@export var mp_cost : int = 0
@export var hp_cost : int = 0

@export_group("Targeting")
@export var target_shape : TargetShape = TargetShape.SINGLE
@export var target_side : TargetSide = TargetSide.OTHER_FACTION
@export var can_target_dead : bool = false
@export var default_target_focus : DefaultTargetFocus = DefaultTargetFocus.AUTO


@export_group("Effects")
@export var effects : Array[Effect] = []
@export var battle_effects : Array[Effect] = []

@export_group("Message")
@export var message_template : String = "{user} uses {skill}."


func get_effects_for_context(ctx : EffectContext) -> Array[Effect]:
	if ctx != null:
		if ctx.mode == EffectContext.Mode.BATTLE:
			if not battle_effects.is_empty():
				return battle_effects
	return effects


func can_pay_cost(user_actor : ActorData) -> bool:
	if user_actor == null:
		return false
	if user_actor.current_hp <= 0:
		return false
	if user_actor.current_mp < mp_cost:
		return false
	if user_actor.current_hp <= hp_cost:
		return false
	return true


func pay_cost(user_actor : ActorData) -> void:
	if user_actor == null:
		return
	user_actor.current_mp = user_actor.current_mp - mp_cost
	user_actor.current_hp = user_actor.current_hp - hp_cost
	user_actor.clamp_vitals()
