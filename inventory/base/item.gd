class_name Item
extends Resource

enum EquipClass {
	NONE = 0,
	WARRIOR = 1,
	THIEF = 2,
	MAGE = 4,
	HEALER = 8,
	ENEMY = 16,
	BOSS = 32,
}

enum ItemType { HPHEAL, MPHEAL, STATUSHEAL, TOOL, KEY, WEAPON, OFFHAND, HEAD, CHEST, ARMS, LEGS, ACCESSORY }

## Availability across field and battle menus
## FIELD_ONLY: usable from field menus only
## BATTLE_ONLY: usable from battle menus only
## ALL: usable from both
enum UseScope { FIELD_ONLY, BATTLE_ONLY, ALL }

## Target shape defines how many battlers are affected per use
enum TargetShape {
	NONE,
	SELF,
	SINGLE,
	ALL
}

## Target side defines which faction is eligible
## BOTH_FACTIONS supports global effects (hits everyone) without requiring an anchor selection
enum TargetSide {
	SAME_FACTION,
	OTHER_FACTION,
	ANY_FACTION,
	BOTH_FACTIONS
}

enum DefaultTargetFocus {
	AUTO,
	SAME_FACTION,
	OTHER_FACTION
}


@export_group("Identity")
## Unique ID of the item
@export var item_id : StringName = &""
## Name of the item
@export var name : String = ""

@export_group("Sorting and Stacking")
## Sort ID of the item[br]
## HPHEAL:0000[br]MPHEAL:1000[br]STATUSHEAL:2000[br]TOOL:3000[br]KEY:4000[br]WEAPON:5000[br]OFFHAND:6000[br]HEAD:7000[br]CHEST:8000[br]ARMS:9000[br]LEGS:10000[br]ACCESSORY:11000
@export var sort_id : int = 0000
## Highest quantity to hold in a stack
@export_range(1, 999) var max_stack_size : int = 99
## If more than one stack can be made of this item
@export var unique : bool = false

@export_group("Type and Presentation")
## Type of the item
@export_enum("HPHEAL", "MPHEAL", "STATUSHEAL", "TOOL", "KEY", "WEAPON", "OFFHAND", "HEAD", "CHEST", "ARMS", "LEGS", "ACCESSORY")
var type : int = ItemType.TOOL
## Sprite used for the item in the description
@export var menu_sprite : Texture2D = null
## Sprite used for the menu (next to the item)
@export var menu_icon : Texture2D = null
## Sprite on the field
@export var field_sprite : Texture2D = null
@export_multiline var description : String = ""

@export_group("Availability")
@export var scope : UseScope = UseScope.ALL

@export_group("Targeting")
## Target shape and side are shared concepts with Skill
@export var target_shape : TargetShape = TargetShape.SINGLE
@export var target_side : TargetSide = TargetSide.ANY_FACTION
## Allows targeting dead battlers (revive items)
@export var can_target_dead : bool = false
@export var default_target_focus : DefaultTargetFocus = DefaultTargetFocus.AUTO

@export_group("Effects")
## Effects that happen when item is used
@export var effects : Array[Effect] = []
## Effects that happen when the item is used in battle
@export var battle_effects : Array[Effect] = []

@export_group("Consumption")
## Item quantity decreases when used
@export var consume_on_use : bool = true

@export_group("Message")
## Battle and field messaging template support
## Common tokens: {user}, {item}
@export_multiline var message_template : String = "{user} uses {item}."

## Shop values
@export_category("Shop")
## If the item can be sold
@export var can_be_sold : bool = true
## Value used to set price in shop
@export var buy_price : int = 0
## Value used when attempting to sell item
@export var sell_price : int = 0

## Only applicable for equipment
@export_category("Equip")
## Who can equip the item
@export_flags("Warrior", "Thief", "Mage", "Healer", "Enemy", "Boss") var can_equip : int = EquipClass.NONE
## If the weapon type is a 2 handed weapon.
@export var two_hand : bool = false
## Effects that activate when equipped
@export var equip_effect : Array[EquipEffect] = []
## Adds to character's max_hp when equipped
@export var hp_bonus : int = 0
## Adds to character's max_mp when equipped
@export var mp_bonus : int = 0
## Adds to character's atk_value when equipped
@export var atk_bonus : int = 0
## Adds to character's def_value when equipped
@export var def_bonus : int = 0
## Adds to character's strength when equipped
@export var strength_bonus : int = 0
## Adds to character's stamina when equipped
@export var stamina_bonus : int = 0
## Adds to character's speed when equipped
@export var speed_bonus : int = 0
## Adds to character's magic when equipped
@export var magic_bonus : int = 0


func can_be_used_by_member(member) -> bool:
	if member == null:
		return false
	if member.char_resource == null:
		return false

	# member.char_resource.char_class uses your @export_enum("WARRIOR","THIEF","MAGE","HEALER")
	var class_index = int(member.char_resource.char_class)

	# Convert enum index to bit flag that matches EquipClass values
	# 0 -> 1 (WARRIOR), 1 -> 2 (THIEF), 2 -> 4 (MAGE), 3 -> 8 (HEALER)
	var class_flag = 1 << class_index

	return (can_equip & class_flag) != 0


func get_effects_for_context(ctx : EffectContext) -> Array[Effect]:
	if ctx != null:
		if ctx.mode == EffectContext.Mode.BATTLE:
			if not battle_effects.is_empty():
				return battle_effects
	return effects


func can_apply_to_target(ctx : EffectContext, target : ActorData) -> bool:
	var list = get_effects_for_context(ctx)
	for effect in list:
		if effect == null:
			continue
		if effect.can_apply(ctx, target):
			return true
	return false


func apply_to_targets(ctx : EffectContext, targets : Array[ActorData]) -> bool:
	var list = get_effects_for_context(ctx)
	var any_applied = false

	for target in targets:
		if target == null:
			continue
		for effect in list:
			if effect == null:
				continue
			if effect.apply(ctx, target):
				any_applied = true

	return any_applied




#class_name Item
#extends Resource
#
#enum EquipClass {
	#NONE = 0,
	#WARRIOR = 1,
	#THIEF = 2,
	#MAGE = 4,
	#HEALER = 8,
	#ENEMY = 16,
	#BOSS = 32,
#}
#
#enum ItemType { HPHEAL, MPHEAL, STATUSHEAL, TOOL, KEY, WEAPON, OFFHAND, HEAD, CHEST, ARMS, LEGS, ACCESSORY }
#
#enum BattleUse {CANNOT, CAN, ONLY}
#enum FieldTargeting { ONE, ALL }
#enum BattleTargeting { ONE, PARTY, ALL }
#
###Unique ID of the item
#@export var item_id : StringName = ""
###Name of the item
#@export var name : String = ""
###Sort ID of the item[br]
###HPHEAL:0000[br]MPHEAL:1000[br]STATUSHEAL:2000[br]TOOL:3000[br]KEY:4000[br]WEAPON:5000[br] OFFHAND:6000[br]HEAD:7000[br]CHEST:8000[br]ARMS:9000[br]LEGS:10000[br]ACCESSORY:11000
#@export var sort_id : int = 0000
###Highest quantity to hold in a stack
#@export_range(1, 999) var max_stack_size : int = 99
###If more than one stack can be made of this item
#@export var unique : bool = false
###Type of the item
#@export_enum("HPHEAL", "MPHEAL", "STATUSHEAL","TOOL", "KEY", "WEAPON", "OFFHAND", "HEAD", "CHEST", "ARMS", "LEGS", "ACCESSORY")
#var type: int = ItemType.TOOL
###Sprite used for the item in the description
#@export var menu_sprite : Texture2D = null
###Sprite used for the menu (next to the item)
#@export var menu_icon : Texture2D = null
###Sprite on the field
#@export var field_sprite : Texture2D = null
#@export_multiline var description : String = ""
###Effects that happen when item is used
#@export var effects : Array[Effect] = []
###Effects that happen when the item is used in battle
#@export var battle_effects : Array[Effect] = []
###Item quantity decreases when used
#@export var one_less_on_use : bool = true
###If the item can be used in battle, or only in battle[br]cannot = 0, can = 1, only = 2
#@export_enum("Cannot", "Can", "Only") var battle_use : int = BattleUse.CANNOT
###If the item targets one member of the party or all when used in field menu
#@export var field_targeting : FieldTargeting = FieldTargeting.ONE
###Who the item's effects target during battle
#@export var battle_targeting : BattleTargeting = BattleTargeting.ONE
#
#
###Shop values
#@export_category("Shop")
###If the item can be sold
#@export var can_be_sold : bool = true
###Value used to set price in shop
#@export var buy_price : int = 0
###Value used when attempting to sell item
#@export var sell_price : int = 0
#
###Only applicable for equipment
#@export_category("Equip")
###Who can equip the item
#@export_flags( "Warrior", "Thief" ,"Mage", "Healer", "Enemy", "Boss" ) var can_equip: int = EquipClass.NONE
###If the weapon type is a 2 handed weapon.
#@export var two_hand : bool = false
###Effects that activate when equipped
#@export var equip_effect : Array[EquipEffect] = []
###Adds to character's max_hp when equipped
#@export var hp_bonus : int = 0 
###Adds to character's max_mp when equipped
#@export var mp_bonus : int = 0
###Adds to character's atk_value when equipped
#@export var atk_bonus : int = 0
###Adds to character's def_value when equipped
#@export var def_bonus : int = 0
###Adds to character's strength when equipped
#@export var strength_bonus : int = 0
###Adds to character's stamina when equipped
#@export var stamina_bonus : int = 0
###Adds to character's speed when equipped
#@export var speed_bonus : int = 0
###Adds to character's magic when equipped
#@export var magic_bonus : int = 0
#
#
#func can_be_used_by_member(member) -> bool:
	#if member == null:
		#return false
	#if member.char_resource == null:
		#return false
#
	## member.char_resource.char_class uses your @export_enum("WARRIOR","THIEF","MAGE","HEALER")
	#var class_index = int(member.char_resource.char_class)
#
	## Convert enum index to bit flag that matches EquipClass values
	## 0 -> 1 (WARRIOR), 1 -> 2 (THIEF), 2 -> 4 (MAGE), 3 -> 8 (HEALER)
	#var class_flag = 1 << class_index
#
	#return (can_equip & class_flag) != 0
#
#
#func get_effects_for_context(ctx : EffectContext) -> Array[Effect]:
	#if ctx != null:
		#if ctx.mode == EffectContext.Mode.BATTLE:
			#if not battle_effects.is_empty():
				#return battle_effects
	#return effects
#
#
#func can_apply_to_target(ctx : EffectContext, target : ActorData) -> bool:
	#var list = get_effects_for_context(ctx)
	#for effect in list:
		#if effect == null:
			#continue
		#if effect.can_apply(ctx, target):
			#return true
	#return false
#
#
#func apply_to_targets(ctx : EffectContext, targets : Array[ActorData]) -> bool:
	#var list = get_effects_for_context(ctx)
	#var any_applied = false
#
	#for target in targets:
		#if target == null:
			#continue
		#for effect in list:
			#if effect == null:
				#continue
			#if effect.apply(ctx, target):
				#any_applied = true
#
	#return any_applied
