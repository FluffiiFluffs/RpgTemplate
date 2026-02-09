class_name PartyMemberData
extends ActorData
## Resource used to hold party member data in the running game

@export_category("Identity")

@export var stats_sprite : Texture2D
@export var class_color : Color = Color()

@export_category("Progression")
##Progress within the current level. On level up, threshold is subtracted as carryover.
@export var current_exp : int = 0
##Experience needed to reach the next level.
@export var next_level_exp : int = 100
##Total experience gained by character (all time).
@export var total_exp : int = 0


@export_category("Stats")
@export var stats_table : StatsTable = null


func rebuild_base_stats() -> void:
	if stats_table == null:
		# Transitional fallback while PartyMemberData resources are being updated.
		super.rebuild_base_stats()
		return

	var level_index : int = level - 1
	if level_index < 0:
		level_index = 0

	# Primary stats authored by StatsTable
	base_strength = _value_from_table(stats_table.strength, level_index, base_strength)
	base_stamina = _value_from_table(stats_table.stamina, level_index, base_stamina)
	base_agility = _value_from_table(stats_table.agility, level_index, base_agility)
	base_magic = _value_from_table(stats_table.magic, level_index, base_magic)
	base_luck = _value_from_table(stats_table.luck, level_index, base_luck)

	# Derived combat stats (simple, deterministic policy)
	base_atk_value = base_strength
	base_def_value = base_stamina
	base_matk_value = base_magic
	base_mdef_value = base_magic

	# Derived vitals from HPSPMod + current primary stats
	var mod : HPSPMod = _resolve_hp_sp_mod()
	if mod != null:
		var hp_mod_value : int = _value_from_table(mod.hp_mod, level_index, 0)
		var sp_mod_value : int = _value_from_table(mod.sp_mod, level_index, 0)

		@warning_ignore("integer_division")
		var computed_hp : int = (base_stamina * hp_mod_value) / mod.hp_divisor
		if computed_hp < 1:
			computed_hp = 1
		base_max_hp = computed_hp

		@warning_ignore("integer_division")
		var computed_sp : int = (base_magic * sp_mod_value) / mod.sp_divisor
		if computed_sp < 0:
			computed_sp = 0
		base_max_sp = computed_sp

	clamp_vitals()


func _resolve_hp_sp_mod() -> HPSPMod:
	if CharDataKeeper != null:
		return CharDataKeeper.hp_sp_mod
	return null


func _value_from_table(values : Array[int], index : int, fallback : int) -> int:
	if values.is_empty():
		return fallback

	var i : int = index
	if i < 0:
		i = 0
	if i >= values.size():
		i = values.size() - 1

	return int(values[i])
