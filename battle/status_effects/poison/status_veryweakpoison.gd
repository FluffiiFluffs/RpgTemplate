class_name StatusVeryWeakPoison
extends StatusEffectPoison

func _init() -> void:
	super()

	tier_name = "Very Weak Poison"
	exclusive_rank = 10

	# Provided tuning
	battle_max_hp_percent_per_turn = 0.003
	field_max_hp_percent_per_step = 0.0015
	stat_percent_decrease = 0.05
