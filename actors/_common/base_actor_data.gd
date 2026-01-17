class_name ActorData
extends Resource

@export_category("REQUIRED")
@export var field_scene : PackedScene = null
@export var battle_scene : PackedScene = null
@export var battle_icon : Texture2D = null
@export var char_resource : CharResource = null

@export_category("Identity")
##Unique identifier for this party member.
@export var id : StringName = ""


@export_category("Progression")
##Current level of party member.
@export_range(1, 99, 1) var level : int = 1
##Current experience held. Resets to 0 upon leveling.
@export var current_exp : int = 0
##Experience needed to reach the next level.
@export var next_level_exp : int = 100
##Total experience gained by character (all time).
@export var total_exp : int = 0

@export_category("Runtime vitals")
##Current HP. This is always clamped against get_max_hp().
@export var current_hp : int = 100
##Current MP. This is always clamped against get_max_mp().
@export var current_mp : int = 0
@export var status_effects :Array[StatusEffect]= []

@export_category("Equipment")
@export var mainhand : Item
@export var offhand : Item
@export var headslot : Item
@export var chestslot : Item
@export var armslot : Item
@export var legslot : Item
@export var accy01 : Item
@export var accy02 : Item
@export var two_handing : bool = false

##Array of default actions that can be taken in battle by the actor.
@export var battle_actions:BattleActions

#region Permanent modifiers
@export_category("Permanent modifiers (flat)")
##Flat permanent change to max_hp from level ups and permanent items.
@export var perm_max_hp_flat : int = 0
##Flat permanent change to max_mp.
@export var perm_max_mp_flat : int = 0
##Flat permanent change to attack value.
@export var perm_atk_flat : int = 0
##Flat permanent change to defense value.
@export var perm_def_flat : int = 0
##Flat permanent change to strength.
@export var perm_strength_flat : int = 0
##Flat permanent change to stamina.
@export var perm_stamina_flat : int = 0
##Flat permanent change to speed.
@export var perm_speed_flat : int = 0
##Flat permanent change to magic.
@export var perm_magic_flat : int = 0
#endregion

#region Buff modifiers

@export_category("Buff modifiers (flat)")
##Flat bonus to max_hp from buffs.
@export var buff_max_hp_flat : int = 0
##Flat bonus to max_mp from buffs.
@export var buff_max_mp_flat : int = 0
##Flat bonus to atk_value from buffs.
@export var buff_atk_flat : int = 0
##Flat bonus to def_value from buffs.
@export var buff_def_flat : int = 0
##Flat bonus to strength from buffs.
@export var buff_strength_flat : int = 0
##Flat bonus to stamina from buffs.
@export var buff_stamina_flat : int = 0
##Flat bonus to speed from buffs.
@export var buff_speed_flat : int = 0
##Flat bonus to magic from buffs.
@export var buff_magic_flat : int = 0


@export_category("Buff modifiers (percent)")
##Percent bonus to max_hp from buffs (0.25 means plus 25 percent).
@export var buff_max_hp_percent : float = 0.0
##Percent bonus to max_mp from buffs (0.25 means plus 25 percent).
@export var buff_max_mp_percent : float = 0.0
##Percent bonus to atk_value from buffs.
@export var buff_atk_percent : float = 0.0
##Percent bonus to def_value from buffs.
@export var buff_def_percent : float = 0.0
##Percent bonus to strength from buffs.
@export var buff_strength_percent : float = 0.0
##Percent bonus to stamina from buffs.
@export var buff_stamina_percent : float = 0.0
##Percent bonus to speed from buffs.
@export var buff_speed_percent : float = 0.0
##Percent bonus to magic from buffs.
@export var buff_magic_percent : float = 0.0
#endregion


func init_from_char_resource(_char_resource : CharResource, _id : StringName = "") -> void:
	if _char_resource == null:
		return

	char_resource = _char_resource

	# Give it a stable id. You can change this logic later if you want.
	if _id == "":
		id = char_resource.char_name
	else:
		id = _id

	# Starting level uses the default from the CharResource.
	level = char_resource.char_level

	# Fresh member, no experience yet.
	current_exp = 0
	total_exp = 0
	# You can leave next_level_exp as whatever you set in the inspector,
	# or later hook it to some ExpTable.get_exp_for_level(level + 1).

	# Start fully healed.
	current_hp = get_max_hp()
	current_mp = get_max_mp()

	# Safety clamp, in case formulas change later.
	clamp_vitals()






#region Basic Getters
##Basic helpers so UI and battle do not poke CharResource directly.

func _get_name() -> String:
	if char_resource != null:
		return char_resource.char_name
	return ""


func _get_class() -> int:
	if char_resource != null:
		return char_resource.char_class
	return 0


func get_faction() -> int:
	if char_resource != null:
		return char_resource.char_faction
	return 0


func get_battle_actions() -> BattleActions:
	if char_resource != null:
		return char_resource.battle_actions
	return null
#endregion

#region Base Stat Getters
# Base layer getters
# (CharResource base plus permanent modifiers.)

func get_base_max_hp() -> int:
	if char_resource == null:
		return max(1, perm_max_hp_flat)
	var base := char_resource.max_hp + perm_max_hp_flat
	if base < 1:
		base = 1
	return base


func get_base_max_mp() -> int:
	if char_resource == null:
		return max(0, perm_max_mp_flat)
	var base := char_resource.max_mp + perm_max_mp_flat
	if base < 0:
		base = 0
	return base


func get_base_strength() -> int:
	if char_resource == null:
		return perm_strength_flat
	var base := char_resource.strength + perm_strength_flat
	return base


func get_base_stamina() -> int:
	if char_resource == null:
		return perm_stamina_flat
	var base := char_resource.stamina + perm_stamina_flat
	return base


func get_base_speed() -> int:
	if char_resource == null:
		return perm_speed_flat
	var base := char_resource.speed + perm_speed_flat
	return base


func get_base_magic() -> int:
	if char_resource == null:
		return perm_magic_flat
	var base := char_resource.magic + perm_magic_flat
	return base


func get_base_atk_value() -> int:
	if char_resource == null:
		return perm_atk_flat
	var base := char_resource.atk_value + perm_atk_flat
	return base


func get_base_def_value() -> int:
	if char_resource == null:
		return perm_def_flat
	var base := char_resource.def_value + perm_def_flat
	return base
#endregion

#region Equipment Helpers
# Equipment layer helpers
# These read bonuses from the equipped Item resources.

func _get_item_hp_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.hp_bonus


func _get_item_mp_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.mp_bonus


func _get_item_atk_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.atk_bonus


func _get_item_def_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.def_bonus


func _get_item_strength_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.strength_bonus


func _get_item_stamina_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.stamina_bonus


func _get_item_speed_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.speed_bonus


func _get_item_magic_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.magic_bonus


func get_equip_max_hp_bonus() -> int:
	var total := 0
	total += _get_item_hp_bonus(headslot)
	total += _get_item_hp_bonus(chestslot)
	total += _get_item_hp_bonus(armslot)
	total += _get_item_hp_bonus(legslot)
	total += _get_item_hp_bonus(accy01)
	total += _get_item_hp_bonus(accy02)
	total += _get_item_hp_bonus(mainhand)
	total += _get_item_hp_bonus(offhand)
	return total


func get_equip_max_mp_bonus() -> int:
	var total := 0
	total += _get_item_mp_bonus(headslot)
	total += _get_item_mp_bonus(chestslot)
	total += _get_item_mp_bonus(armslot)
	total += _get_item_mp_bonus(legslot)
	total += _get_item_mp_bonus(accy01)
	total += _get_item_mp_bonus(accy02)
	total += _get_item_mp_bonus(mainhand)
	total += _get_item_mp_bonus(offhand)
	return total


func get_equip_strength_bonus() -> int:
	var total := 0
	total += _get_item_strength_bonus(headslot)
	total += _get_item_strength_bonus(chestslot)
	total += _get_item_strength_bonus(armslot)
	total += _get_item_strength_bonus(legslot)
	total += _get_item_strength_bonus(accy01)
	total += _get_item_strength_bonus(accy02)
	total += _get_item_strength_bonus(mainhand)
	total += _get_item_strength_bonus(offhand)
	return total


func get_equip_stamina_bonus() -> int:
	var total := 0
	total += _get_item_stamina_bonus(headslot)
	total += _get_item_stamina_bonus(chestslot)
	total += _get_item_stamina_bonus(armslot)
	total += _get_item_stamina_bonus(legslot)
	total += _get_item_stamina_bonus(accy01)
	total += _get_item_stamina_bonus(accy02)
	total += _get_item_stamina_bonus(mainhand)
	total += _get_item_stamina_bonus(offhand)
	return total


func get_equip_speed_bonus() -> int:
	var total := 0
	total += _get_item_speed_bonus(headslot)
	total += _get_item_speed_bonus(chestslot)
	total += _get_item_speed_bonus(armslot)
	total += _get_item_speed_bonus(legslot)
	total += _get_item_speed_bonus(accy01)
	total += _get_item_speed_bonus(accy02)
	total += _get_item_speed_bonus(mainhand)
	total += _get_item_speed_bonus(offhand)
	return total


func get_equip_magic_bonus() -> int:
	var total := 0
	total += _get_item_magic_bonus(headslot)
	total += _get_item_magic_bonus(chestslot)
	total += _get_item_magic_bonus(armslot)
	total += _get_item_magic_bonus(legslot)
	total += _get_item_magic_bonus(accy01)
	total += _get_item_magic_bonus(accy02)
	total += _get_item_magic_bonus(mainhand)
	total += _get_item_magic_bonus(offhand)
	return total


func get_equip_atk_bonus() -> int:
	var total := 0
	total += _get_item_atk_bonus(headslot)
	total += _get_item_atk_bonus(chestslot)
	total += _get_item_atk_bonus(armslot)
	total += _get_item_atk_bonus(legslot)
	total += _get_item_atk_bonus(accy01)
	total += _get_item_atk_bonus(accy02)
	total += _get_item_atk_bonus(mainhand)
	total += _get_item_atk_bonus(offhand)
	return total


func get_equip_def_bonus() -> int:
	var total := 0
	total += _get_item_def_bonus(headslot)
	total += _get_item_def_bonus(chestslot)
	total += _get_item_def_bonus(armslot)
	total += _get_item_def_bonus(legslot)
	total += _get_item_def_bonus(accy01)
	total += _get_item_def_bonus(accy02)
	total += _get_item_def_bonus(mainhand)
	total += _get_item_def_bonus(offhand)
	return total
#endregion

#region Final Stats
# Final effective stats: base (with permanent) + equip + buffs

func get_max_hp() -> int:
	var base := get_base_max_hp()
	var equip_bonus := get_equip_max_hp_bonus()
	var total := base + equip_bonus + buff_max_hp_flat
	total = int(float(total) * (1.0 + buff_max_hp_percent))
	if total < 1:
		total = 1
	return total


func get_max_mp() -> int:
	var base := get_base_max_mp()
	var equip_bonus := get_equip_max_mp_bonus()
	var total := base + equip_bonus + buff_max_mp_flat
	total = int(float(total) * (1.0 + buff_max_mp_percent))
	if total < 0:
		total = 0
	return total


func get_strength() -> int:
	var base := get_base_strength()
	var equip_bonus := get_equip_strength_bonus()
	var total := base + equip_bonus + buff_strength_flat
	total = int(float(total) * (1.0 + buff_strength_percent))
	return total


func get_stamina() -> int:
	var base := get_base_stamina()
	var equip_bonus := get_equip_stamina_bonus()
	var total := base + equip_bonus + buff_stamina_flat
	total = int(float(total) * (1.0 + buff_stamina_percent))
	return total


func get_speed() -> int:
	var base := get_base_speed()
	var equip_bonus := get_equip_speed_bonus()
	var total := base + equip_bonus + buff_speed_flat
	total = int(float(total) * (1.0 + buff_speed_percent))
	return total


func get_magic() -> int:
	var base := get_base_magic()
	var equip_bonus := get_equip_magic_bonus()
	var total := base + equip_bonus + buff_magic_flat
	total = int(float(total) * (1.0 + buff_magic_percent))
	return total


func get_atk_value() -> int:
	var base := get_base_atk_value()
	var equip_bonus := get_equip_atk_bonus()
	var total := base + equip_bonus + buff_atk_flat
	total = int(float(total) * (1.0 + buff_atk_percent))
	return total


func get_def_value() -> int:
	var base := get_base_def_value()
	var equip_bonus := get_equip_def_bonus()
	var total := base + equip_bonus + buff_def_flat
	total = int(float(total) * (1.0 + buff_def_percent))
	return total
#endregion

##Clamp current_hp and current_mp after any change to gear, buffs or permanent stats.[br]
##Call after changing equipment, adding or removing buffs or debuffs, after level up, or after a permanent stat item.
func clamp_vitals() -> void:
	var max_hp := get_max_hp()
	var max_mp := get_max_mp()

	if current_hp > max_hp:
		current_hp = max_hp
	if current_hp < 0:
		current_hp = 0

	if current_mp > max_mp:
		current_mp = max_mp
	if current_mp < 0:
		current_mp = 0
		
