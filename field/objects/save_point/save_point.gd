class_name SavePoint extends Node2D

@onready var area_2d: Area2D = %Area2D
@onready var normal_sparkle: GPUParticles2D = %NormalSparkle
@onready var touch_sparkle: GPUParticles2D = %TouchSparkle

var is_touching : bool = false

func _ready()->void:
	area_2d.body_entered.connect(on_body_entered)
	area_2d.body_exited.connect(on_body_exited)
	touch_sparkle.emitting = false
	
func on_body_entered(body : FieldPartyMember)->void:
	if body == CharDataKeeper.controlled_character:
		touch_sparkle.restart()
		is_touching = true
		
func on_body_exited(body : FieldPartyMember)->void:
	if body == CharDataKeeper.controlled_character:
		touch_sparkle.emitting = false
		is_touching = false

func _unhandled_input(_event: InputEvent) -> void:
	if GameState.gamestate == GameState.State.FIELD:
		if is_touching:
			if Input.is_action_just_pressed("confirm_input"):
				##open save menu
				SaveManager.save_load_menu.show_saveload_menu()
				SaveManager.save_load_menu.menu_mode = SaveLoadMenu.MODE.SAVE
				GameState.gamestate = GameState.State.SAVELOADMENU
			
			pass
		pass
