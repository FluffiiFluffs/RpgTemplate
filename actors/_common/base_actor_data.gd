class_name ActorData
extends Resource

@export_category("REQUIRED")
@export var field_scene : PackedScene = null
@export var battle_scene : PackedScene = null
@export var battle_icon : Texture2D = null

@export_category("Identity")
##Unique identifier for this party member.
##TODO This needs to be moved to PartyMemberData since it pertains specifically to party members
@export var actor_id : StringName = &""
##Name displayed in UI and battle messaging system
##Should not be empty
@export var display_name : String = ""
##The class of the actor
##Maybe needs to live in PartyMemberData, too like actor_id
@export_enum("WARRIOR","THIEF","MAGE","HEALER") var actor_class : int = 0

##Faction of the actor
@export_enum("PARTY","NPC","ENEMY","BOSS") var actor_faction : int = 0
 
@export_category("Level")
##Current level of party member.
@export_range(1, 99, 1) var level : int = 1

@export_category("Base Stats")
## Base layer for the current level, unmodified.
## PartyMemberData will later populate these from StatsTable.
## EnemyData will later author these directly.
##Base value of HP for the actor
@export var base_max_hp : int = 0
##Base value of SP for the actor
@export var base_max_sp : int = 0

##Base ATK value for the actor
@export var base_atk_value : int = 0
##Base DEF value for the actor
@export var base_def_value : int = 0
##Base Magic ATK value for the actor
@export var base_matk_value : int = 0
##Base Magic DEF value for the actor
@export var base_mdef_value : int = 0

##Base STR for the actor
@export var base_strength : int = 0
##Base STM for the actor
@export var base_stamina : int = 0
##Base AGI for the actor
@export var base_agility : int = 0
##Base MAG for the actor
@export var base_magic : int = 0
##Base LCK for the actor
@export var base_luck : int = 0








@export_category("Runtime vitals")
##Current HP. This is always clamped against get_max_hp().
@export var current_hp : int = 100
##Current MP. This is always clamped against get_max_sp().
@export var current_sp : int = 0
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

@export_category("Actions and Skills")
##Array of default actions that can be taken in battle by the actor.
@export var battle_actions:BattleActions
@export var skills : Array[Skill] = []
@export var normal_attack_skill : NormalAttack = null
##If the actor can dodge in battle
@export var can_dodge : bool = true
##If the actor can parry (and riposte) in battle
@export var can_parry : bool = false

#region Permanent modifiers
@export_category("Permanent modifiers (flat)")
##Flat permanent change to max_hp from level ups and permanent items.
@export var perm_max_hp_flat : int = 0
##Flat permanent change to max_sp.
@export var perm_max_sp_flat : int = 0
##Flat permanent change to attack value.
@export var perm_atk_flat : int = 0
##Flat permanent change to defense value.
@export var perm_def_flat : int = 0
##Flat permanent change to strength.
@export var perm_strength_flat : int = 0
##Flat permanent change to stamina.
@export var perm_stamina_flat : int = 0
##Flat permanent change to agility.
@export var perm_agility_flat : int = 0
##Flat permanent change to magic.
@export var perm_magic_flat : int = 0
##Flat permanent change to luck.
@export var perm_luck_flat : int = 0
#endregion

#region Buff modifiers

@export_category("Buff modifiers (flat)")
##Flat bonus to max_hp from buffs.
@export var buff_max_hp_flat : int = 0
##Flat bonus to max_sp from buffs.
@export var buff_max_sp_flat : int = 0
##Flat bonus to atk_value from buffs.
@export var buff_atk_flat : int = 0
##Flat bonus to def_value from buffs.
@export var buff_def_flat : int = 0
##Flat bonus to strength from buffs.
@export var buff_strength_flat : int = 0
##Flat bonus to stamina from buffs.
@export var buff_stamina_flat : int = 0
##Flat bonus to agility from buffs.
@export var buff_agility_flat : int = 0
##Flat bonus to magic from buffs.
@export var buff_magic_flat : int = 0
##Flat bonus to luck from buffs.
@export var buff_luck_flat : int = 0



@export_category("Buff modifiers (percent)")
##Percent bonus to max_hp from buffs (0.25 means plus 25 percent).
@export var buff_max_hp_percent : float = 0.0
##Percent bonus to max_sp from buffs (0.25 means plus 25 percent).
@export var buff_max_sp_percent : float = 0.0
##Percent bonus to atk_value from buffs.
@export var buff_atk_percent : float = 0.0
##Percent bonus to def_value from buffs.
@export var buff_def_percent : float = 0.0
##Percent bonus to strength from buffs.
@export var buff_strength_percent : float = 0.0
##Percent bonus to stamina from buffs.
@export var buff_stamina_percent : float = 0.0
##Percent bonus to agility from buffs.
@export var buff_agility_percent : float = 0.0
##Percent bonus to magic from buffs.
@export var buff_magic_percent : float = 0.0
##Percent bonus to luck from buffs.
@export var buff_luck_percent : float = 0.0

#endregion


## Structure:
## _stat_modifiers[stat_key][source_key] = { "flat": int, "percent": float }
var _stat_modifiers : Dictionary = {}


const STAT_MAX_HP : StringName = &"max_hp"
const STAT_MAX_SP : StringName = &"max_sp"
const STAT_ATK_VALUE : StringName = &"atk_value"
const STAT_DEF_VALUE : StringName = &"def_value"
const STAT_STRENGTH : StringName = &"strength"
const STAT_STAMINA : StringName = &"stamina"
const STAT_AGILITY : StringName = &"agility"
const STAT_MAGIC : StringName = &"magic"
const STAT_LUCK : StringName = &"luck"



func set_level_and_rebuild(new_level : int) -> void:
	var clamped : int = clampi(new_level, 1, 99)
	if level == clamped:
		return
	level = clamped
	rebuild_base_stats()


func add_levels_and_rebuild(delta : int) -> void:
	set_level_and_rebuild(level + delta)


func get_actor_class_name() -> String:
	match get_actor_class():
		0:
			return "WARRIOR"
		1:
			return "THIEF"
		2:
			return "MAGE"
		3:
			return "HEALER"
		_:
			return ""




#region Basic Getters
func get_display_name() -> String:
	if display_name != "":
		return display_name
	return ""


## Returns the actor_class enum value (0..3).
func get_actor_class() -> int:
	return actor_class



## Returns the actor_faction enum value (0..3).
func get_actor_faction() -> int:
	return actor_faction
#endregion



## Backwards compatible helpers used around the project today.
func _get_name() -> String:
	return get_display_name()

## Returns the class of the actor
func _get_class() -> int:
	return get_actor_class()

## Returns the faction of the actor
func get_faction() -> int:
	return get_actor_faction()

## Returns array of battle actions for the actor
func get_battle_actions() -> BattleActions:
	return battle_actions
#endregion






#region Base Stat Getters
# Base layer getters
# (Base Stats plus permanent modifiers.)

func _has_base_stats() -> bool:
	return base_max_hp > 0


func get_base_max_hp() -> int:
	var base_total : int = base_max_hp + perm_max_hp_flat
	if base_total < 1:
		base_total = 1
	return base_total


func get_base_max_sp() -> int:
	var base_total : int = base_max_sp + perm_max_sp_flat
	if base_total < 0:
		base_total = 0
	return base_total

func get_base_strength() -> int:
	return base_strength + perm_strength_flat

func get_base_stamina() -> int:
	return base_stamina + perm_stamina_flat

func get_base_agility() -> int:
	return base_agility + perm_agility_flat

func get_base_magic() -> int:
	return base_magic + perm_magic_flat

func get_base_luck() -> int:
	return base_luck + perm_luck_flat

func get_base_atk_value() -> int:
	return base_atk_value + perm_atk_flat

func get_base_def_value() -> int:
	return base_def_value + perm_def_flat

#endregion


#region Equipment Helpers
# Equipment layer helpers
# These read bonuses from the equipped Item resources.

func _get_item_hp_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.hp_bonus


func _get_item_sp_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.sp_bonus


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


func _get_item_agility_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.agility_bonus


func _get_item_magic_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.magic_bonus
	
func _get_item_luck_bonus(item : Item) -> int:
	if item == null:
		return 0
	return item.luck_bonus



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


func get_equip_max_sp_bonus() -> int:
	var total := 0
	total += _get_item_sp_bonus(headslot)
	total += _get_item_sp_bonus(chestslot)
	total += _get_item_sp_bonus(armslot)
	total += _get_item_sp_bonus(legslot)
	total += _get_item_sp_bonus(accy01)
	total += _get_item_sp_bonus(accy02)
	total += _get_item_sp_bonus(mainhand)
	total += _get_item_sp_bonus(offhand)
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


func get_equip_agility_bonus() -> int:
	var total := 0
	total += _get_item_agility_bonus(headslot)
	total += _get_item_agility_bonus(chestslot)
	total += _get_item_agility_bonus(armslot)
	total += _get_item_agility_bonus(legslot)
	total += _get_item_agility_bonus(accy01)
	total += _get_item_agility_bonus(accy02)
	total += _get_item_agility_bonus(mainhand)
	total += _get_item_agility_bonus(offhand)
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
	
func get_equip_luck_bonus() -> int:
	var total = 0
	total += _get_item_luck_bonus(headslot)
	total += _get_item_luck_bonus(chestslot)
	total += _get_item_luck_bonus(armslot)
	total += _get_item_luck_bonus(legslot)
	total += _get_item_luck_bonus(accy01)
	total += _get_item_luck_bonus(accy02)
	total += _get_item_luck_bonus(mainhand)
	total += _get_item_luck_bonus(offhand)
	return total

#endregion

#region Final Stats
# Final effective stats: base (with permanent) + equip + buffs
func get_max_hp() -> int:
	var base := get_base_max_hp()
	var equip_bonus := get_equip_max_hp_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_MAX_HP)
	var total := base + equip_bonus + buff_max_hp_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_max_hp_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	if total < 1:
		total = 1
	return total


func get_max_sp() -> int:
	var base := get_base_max_sp()
	var equip_bonus := get_equip_max_sp_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_MAX_SP)
	var total := base + equip_bonus + buff_max_sp_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_max_sp_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	if total < 0:
		total = 0
	return total


func get_strength() -> int:
	var base := get_base_strength()
	var equip_bonus := get_equip_strength_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_STRENGTH)
	var total := base + equip_bonus + buff_strength_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_strength_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total


func get_stamina() -> int:
	var base := get_base_stamina()
	var equip_bonus := get_equip_stamina_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_STAMINA)
	var total := base + equip_bonus + buff_stamina_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_stamina_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total


func get_agility() -> int:
	var base := get_base_agility()
	var equip_bonus := get_equip_agility_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_AGILITY)
	var total := base + equip_bonus + buff_agility_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_agility_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total


func get_magic() -> int:
	var base := get_base_magic()
	var equip_bonus := get_equip_magic_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_MAGIC)
	var total := base + equip_bonus + buff_magic_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_magic_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total


func get_luck() -> int:
	var base = get_base_luck()
	var equip_bonus = get_equip_luck_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_LUCK)
	var total = base + equip_bonus + buff_luck_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_luck_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total



func get_atk_value() -> int:
	var base := get_base_atk_value()
	var equip_bonus := get_equip_atk_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_ATK_VALUE)
	var total := base + equip_bonus + buff_atk_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_atk_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total


func get_def_value() -> int:
	var base := get_base_def_value()
	var equip_bonus := get_equip_def_bonus()

	var mods : Dictionary = get_stat_modifier_totals(STAT_DEF_VALUE)
	var total := base + equip_bonus + buff_def_flat + int(mods.get("flat", 0))

	var mult : float = 1.0 + buff_def_percent + float(mods.get("percent", 0.0))
	if mult < 0.0:
		mult = 0.0
	total = int(float(total) * mult)

	return total

#endregion





## Copies identity from CharResource only when the ActorData fields are UNSET.
## Probably not needed since UNSET is not going to be used


## Rebuilds the base stat layer in one call, then clamps vitals.
## Default behavior only fills base stats when they are uninitialized.
## PartyMemberData and EnemyData can override this later.
## not needed since Char resource is going to be gone soon
func rebuild_base_stats() -> void:
	clamp_vitals()




##Clamp current_hp and current_sp after any change to gear, buffs or permanent stats.[br]
##Call after changing equipment, adding or removing buffs or debuffs, after level up, or after a permanent stat item.
func clamp_vitals() -> void:
	var max_hp := get_max_hp()
	var max_sp := get_max_sp()

	if current_hp > max_hp:
		current_hp = max_hp
	if current_hp < 0:
		current_hp = 0

	if current_sp > max_sp:
		current_sp = max_sp
	if current_sp < 0:
		current_sp = 0
		




#region Stat modifier aggregator
## Runtime stackable modifiers per stat, keyed by source.
## Example:
## set_stat_modifier(STAT_AGILITY, &"status_haste", 0, 0.25)

func set_stat_modifier(stat_key : StringName, source_key : StringName, flat : int = 0, percent : float = 0.0) -> void:
	if stat_key == &"":
		return
	if source_key == &"":
		return

	var bucket : Dictionary = {}
	if _stat_modifiers.has(stat_key):
		bucket = _stat_modifiers[stat_key]

	# Treat zero entries as removal
	if flat == 0 and is_zero_approx(percent):
		if bucket.has(source_key):
			bucket.erase(source_key)
	else:
		bucket[source_key] = {
			"flat": flat,
			"percent": percent,
		}

	if bucket.is_empty():
		if _stat_modifiers.has(stat_key):
			_stat_modifiers.erase(stat_key)
	else:
		_stat_modifiers[stat_key] = bucket


func remove_stat_modifier(stat_key : StringName, source_key : StringName) -> void:
	if stat_key == &"":
		return
	if source_key == &"":
		return
	if not _stat_modifiers.has(stat_key):
		return

	var bucket : Dictionary = _stat_modifiers[stat_key]
	if bucket.has(source_key):
		bucket.erase(source_key)

	if bucket.is_empty():
		_stat_modifiers.erase(stat_key)
	else:
		_stat_modifiers[stat_key] = bucket


func clear_all_stat_modifiers() -> void:
	_stat_modifiers.clear()


func get_stat_modifier_totals(stat_key : StringName) -> Dictionary:
	var out : Dictionary = {
		"flat": 0,
		"percent": 0.0,
	}

	if not _stat_modifiers.has(stat_key):
		return out

	var bucket : Dictionary = _stat_modifiers[stat_key]
	for entry in bucket.values():
		if typeof(entry) != TYPE_DICTIONARY:
			continue
		out["flat"] = int(out["flat"]) + int(entry.get("flat", 0))
		out["percent"] = float(out["percent"]) + float(entry.get("percent", 0.0))

	return out
#endregion
