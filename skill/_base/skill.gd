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
### High level intent classification for skill uses.
### This is authored explicitly per skill, no automatic inference.
#enum Intent {
	#UTILITY = 0,
	#HARMFUL = 1,
	#BENEFICIAL = 2,
	#MIXED = 3
#}


enum SortSubcategory {
	HP_RECOVERY = 0,
	FULL_RECOVERY = 1,
	REVIVE = 2,
	STATUS_RECOVERY = 3,
	SP_RECOVERY = 4,
	SINGLE_TARGET_DAMAGE = 5,
	ALL_TARGET_DAMAGE = 6,
	ALLY_BUFFS = 7,
	ENEMY_DEBUFFS = 8,
	ENEMY_STATUS_EFFECTS = 9,
}

enum Stat {HP, SP, STR, STM, AGI, MAG, LCK}

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

## Power level for skills that cause direct damage or heal.
## Not used for abilities that do not deal with HP (also does not include poison)
## Used on a case-by-case basis
@export_group("Power")
## If power to be used in the calculation at (more of a dev-indicator)
@export var use_power_calc : bool = false
## Which stat is used to boost the skill's power
@export var scaler_stat : Stat = Stat.STR
## Power of the skill.
## This will be displayed within the UI (eventually), so its value is 10x the amount of stat scaling used. 
	## example : 1.0 = 10, 1.5 = 15
@export var scaler_amount : int = 10

@export_group("Targeting")
## Targeting behavior used by CommandController during skill targeting.
@export var target_shape : TargetShape = TargetShape.SINGLE
@export var target_side : TargetSide = TargetSide.ANY_FACTION
## When false, CommandController excludes battlers with current_hp <= 0 from the valid target set.
@export var can_target_dead : bool = false
## Initial focus hint applied when opening targeting for this skill.
@export var default_target_focus : DefaultTargetFocus = DefaultTargetFocus.AUTO
## Gameplay classification for systems that need a stable notion of offensive vs beneficial.
#@export var intent : Intent = Intent.UTILITY

@export_group("Menu Sorting")
@export var sort_subcategory : SortSubcategory = SortSubcategory.SINGLE_TARGET_DAMAGE


@export_category("Tuning")
##If the skill can miss
@export var can_miss : bool = true
##if the skill can be dodged
@export var can_dodge : bool = true
##If the skill can be parried
@export var can_parry : bool = true
##How much variance the skill damage should have from its base raw damage value
@export var variance_percent : float = 10.0


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



func get_sort_main_category_key() -> String:
	match sort_subcategory:
		SortSubcategory.HP_RECOVERY:
			return "RECOVERY"
		SortSubcategory.FULL_RECOVERY:
			return "RECOVERY"
		SortSubcategory.REVIVE:
			return "RECOVERY"
		SortSubcategory.STATUS_RECOVERY:
			return "RECOVERY"
		SortSubcategory.SP_RECOVERY:
			return "RECOVERY"
		SortSubcategory.SINGLE_TARGET_DAMAGE:
			return "ATTACK"
		SortSubcategory.ALL_TARGET_DAMAGE:
			return "ATTACK"
		SortSubcategory.ALLY_BUFFS:
			return "EFFECT"
		SortSubcategory.ENEMY_DEBUFFS:
			return "EFFECT"
		SortSubcategory.ENEMY_STATUS_EFFECTS:
			return "EFFECT"

	return "EFFECT"
	
	
func get_sort_subcategory_rank() -> int:
	match sort_subcategory:
		SortSubcategory.HP_RECOVERY:
			return 0
		SortSubcategory.FULL_RECOVERY:
			return 1
		SortSubcategory.REVIVE:
			return 2
		SortSubcategory.STATUS_RECOVERY:
			return 3
		SortSubcategory.SP_RECOVERY:
			return 4
		SortSubcategory.SINGLE_TARGET_DAMAGE:
			return 5
		SortSubcategory.ALL_TARGET_DAMAGE:
			return 6
		SortSubcategory.ALLY_BUFFS:
			return 7
		SortSubcategory.ENEMY_DEBUFFS:
			return 8
		SortSubcategory.ENEMY_STATUS_EFFECTS:
			return 9

	return 999



func is_beneficial_subcategory() -> bool:
	match sort_subcategory:
		SortSubcategory.HP_RECOVERY:
			return true
		SortSubcategory.FULL_RECOVERY:
			return true
		SortSubcategory.REVIVE:
			return true
		SortSubcategory.STATUS_RECOVERY:
			return true
		SortSubcategory.SP_RECOVERY:
			return true
		SortSubcategory.ALLY_BUFFS:
			return true

	return false


func is_harmful_subcategory() -> bool:
	match sort_subcategory:
		SortSubcategory.SINGLE_TARGET_DAMAGE:
			return true
		SortSubcategory.ALL_TARGET_DAMAGE:
			return true
		SortSubcategory.ENEMY_DEBUFFS:
			return true
		SortSubcategory.ENEMY_STATUS_EFFECTS:
			return true

	return false


func is_field_usable_subcategory() -> bool:
	return is_beneficial_subcategory()


func get_auto_target_focus_from_subcategory() -> int:
	if is_beneficial_subcategory():
		return DefaultTargetFocus.SAME_FACTION

	if is_harmful_subcategory():
		return DefaultTargetFocus.OTHER_FACTION

	return DefaultTargetFocus.SAME_FACTION


func qualifies_as_haste_beneficial() -> bool:
	return is_beneficial_subcategory()


func qualifies_as_haste_offensive() -> bool:
	return is_harmful_subcategory()


func get_scaler_stat_value(user_actor : ActorData) -> int:
	if user_actor == null:
		return 0

	match scaler_stat:
		Stat.HP:
			return user_actor.current_hp
		Stat.SP:
			return user_actor.current_sp
		Stat.STR:
			return user_actor.get_strength()
		Stat.STM:
			return user_actor.get_stamina()
		Stat.AGI:
			return user_actor.get_agility()
		Stat.MAG:
			return user_actor.get_magic()
		Stat.LCK:
			return user_actor.get_luck()

	return 0


func get_power_scaled_amount(user_actor : ActorData, base_amount : int) -> int:
	if not use_power_calc:
		return base_amount

	if user_actor == null:
		return base_amount

	var stat_value : int = get_scaler_stat_value(user_actor)
	var multiplier : float = float(scaler_amount) / 10.0
	var bonus : int = roundi(float(stat_value) * multiplier)
	var final_amount : int = base_amount + bonus

	if final_amount < 0:
		return 0

	return final_amount
