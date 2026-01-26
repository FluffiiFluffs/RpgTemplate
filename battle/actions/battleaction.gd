## battle_action.gd
## Root data definition for a battle command.
## Shared fields only: UI category, backend ActionType routing, targeting rules, costs, timing, and presentation keys.
## Concrete actions should inherit from this and add their own exported parameters (power, element, steal chance, etc).
## Do not store runtime state on this resource (targets, last roll, last damage, user refs).
class_name BattleAction
extends Resource

enum Category {
	ATTACK,
	SKILL,
	ITEM,
	DEFEND,
	RUN,
	SPECIAL
}

## Backend routing key used by ActionResolver to choose which resolution routine runs.
enum ActionType {
	NORMAL_ATTACK,
	DEFEND,
	RUN,
	USE_ITEM,
	USE_SKILL,
}

## How targets are selected (shape), independent of faction wording.
enum TargetShape {
	NONE,    # no targets
	SELF,    # user only
	SINGLE,  # one selected target
	ALL      # all valid targets on the chosen side
}

## Which side is valid relative to the user.
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
@export var action_name: String = ""
@export_multiline var description: String = ""
@export var icon: Texture2D = null
@export var category: Category = Category.SKILL

@export_group("Backend")
@export var type: ActionType = ActionType.NORMAL_ATTACK

@export_group("Targeting")
@export var target_shape: TargetShape = TargetShape.SINGLE
@export var target_side: TargetSide = TargetSide.OTHER_FACTION
#@export var min_targets: int = 1 # No need for this
#@export var max_targets: int = 1 #No need for this
#@export var allow_self_target: bool = false #should always allow targeting of anyone on the field
@export var can_target_dead: bool = false
@export var default_target_focus: DefaultTargetFocus = DefaultTargetFocus.AUTO


@export_group("Multi target toggle")
## Final Fantasy style toggle: allow switching SINGLE <-> ALL at selection time.
@export var supports_expand: bool = false
@export var expanded_shape: TargetShape = TargetShape.ALL
@export var expanded_power_scalar: float = 0.75
@export var expanded_mp_cost_delta: int = 0

@export_group("Costs and timing")
@export var mp_cost: int = 0
@export var hp_cost: int = 0
#@export var stamina_cost: int = 0 #HP/MP should be the only valid costs. Stamina is not even a stat
#@export var consumes_turn: bool = true
@export var priority: int = 0
@export var speed_multiplier: float = 1.0

@export_group("Presentation")
@export var message_template: String = "{user} uses {action}."
@export var animation_key: StringName = &""
@export var sfx_key: StringName = &""
@export var vfx_key: StringName = &""
