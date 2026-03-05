class_name SkillsUI extends Control

@onready var hider: PanelContainer = %Hider


func _ready()->void:
	hider.queue_free()
	pass


func force_close_for_load() -> void:
	# Skills menu is not implemented yet. Keep as a safe no op.
	pass
