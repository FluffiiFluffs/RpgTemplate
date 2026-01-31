class_name StatusWeakPoison
extends StatusEffectPoison

func _init() -> void:
	super()

	tier_name = "Weak Poison"
	exclusive_rank = 20

	# Placeholder tuning, adjust later
	battle_max_hp_percent_per_turn = 0.006
	field_max_hp_percent_per_step = 0.003
	stat_percent_decrease = 0.08
