class_name Main
extends Node
##Main.gd
##Main scene
##The main scene of the game. Used to manage almost all aspects of the game outside of global functions.

#region Node References
@onready var field_root : Node2D = %FieldRoot
@onready var field_scene_container : Node2D = %FieldSceneContainer
@onready var field_vfx : Node2D = %FieldVFX
@onready var field_camera_rig : FieldCameraRig= %FieldCameraRig
@onready var field_camera : Camera2D = %FieldCamera
@onready var battle_root := %BattleRoot
@onready var transition_layer : TransitionLayer = %TransitionLayer
@onready var audio_root : Node = %AudioRoot
@onready var runtime : Node = %Runtime
@onready var title_menu_layer : Node = %TitleMenuLayer



#endregion Node References

#region Export Variables
@export var title_menu_scene : PackedScene = null
@export var starting_field_scene : PackedScene = null
@export var starting_spawn_id : StringName = &"Start"

const BATTLE_SCENE = preload("uid://h63ncjrxunau")
#endregion Export Variables



#region Variables
var current_field_scene : FieldScene = null
var current_battle_scene : BattleScene = null
var battling_field_enemy_scene : FieldEnemy = null
var title_menu_instance : CanvasLayer = null


#endregion Variables


func _ready()->void:
	SceneManager.main_scene = self



#region Battle
func start_battle(egroup : EnemyGroup)->void:
	if GameState.gamestate == GameState.State.BATTLE:
		printerr("ALREADY IN BATTLE STATE!")
		return
	GameState.gamestate = GameState.State.BATTLE #swap game state to battle
	transition_layer.play_begin() #play transition to black screen
	field_root.process_mode = Node.PROCESS_MODE_DISABLED #stop processing the field
	await transition_layer.animation_player.animation_finished #wait until it's fully black
	field_camera_rig.deactivate() #deactivate the field camera
	field_root.visible = false
	var new_battle_scene := BATTLE_SCENE.instantiate() as BattleScene #makes new battle scene
	battle_root.add_child(new_battle_scene) #Puts the battle scene into the tree
	current_battle_scene = new_battle_scene #Saves reference to battle scene for later
	new_battle_scene.enemy_group = egroup #Stores reference to the EnemyGroup from the enemy
	battle_root.visible = true #makes battle visible
	new_battle_scene.battle_camera_rig.activate() #makes battle camera active camera
	await new_battle_scene.setup_all() #Sets up the battle (party, enemies, turns)
	await get_tree().process_frame
	transition_layer.play_end()
	await transition_layer.animation_player.animation_finished
	await current_battle_scene.show_intro_message() #Displays intro message
	current_battle_scene.turn_manager.round_next_setup() #Changes battle state to "ROUND_SETUP", sorts turn order, updates turn UI
	

##After battle is completely finished (loot,xp given), gets rid of the battle scene, sets game state back to field, etc	
func end_battle_victory_normal()->void:
	transition_layer.play_begin() #fades the screen to black
	await transition_layer.animation_player.animation_finished #waits until the screen is black
	battle_root.visible = false #Hides battle
	
	clear_battle_scene() #Removes any battle scenes from memory
	#current_battle_scene = null #sets to null just to be safe
	field_root.process_mode = Node.PROCESS_MODE_INHERIT #allows field root to process
	field_camera_rig.activate() #reactivates field camera
	field_camera_rig.follow_player() #sets follow back to player
	if battling_field_enemy_scene != null:
		battling_field_enemy_scene.enemy_killed()
	destroy_chasing_enemies()
	GameState.gamestate = GameState.State.FIELD #swap game state back to field
	field_root.set_deferred("visible", true)
	transition_layer.play_end()
	await transition_layer.animation_player.animation_finished

##After battle is completely finished (loot,xp given), gets rid of the battle scene, sets game state back to field, etc	
func end_battle_run()->void:
	transition_layer.play_begin() #fades the screen to black
	await transition_layer.animation_player.animation_finished #waits until the screen is black
	battle_root.visible = false #Hides battle
	
	clear_battle_scene() #Removes any battle scenes from memory
	#current_battle_scene = null #sets to null just to be safe
	field_root.process_mode = Node.PROCESS_MODE_INHERIT #allows field root to process
	field_camera_rig.activate() #reactivates field camera
	field_camera_rig.follow_player() #sets follow back to player
	if battling_field_enemy_scene != null:
		battling_field_enemy_scene.enemy_killed()
	destroy_chasing_enemies()
	GameState.gamestate = GameState.State.FIELD #swap game state back to field
	field_root.set_deferred("visible", true)
	transition_layer.play_end()
	await transition_layer.animation_player.animation_finished




#cleans up any enemies that have touched the player in case there were more than 1
func destroy_chasing_enemies()->void:
	for child in current_field_scene.enemy_spawners.get_children():
		if child is EnemySpawner:
			for en in child.get_children():
				if en is FieldEnemy:
					#if en.touched_player:
					if en.has_chased_player:
						en.queue_free()
					#if en.was_spawned: #ALERT This causes enemies to spawn constantly! BUG!
						#en.enemy_spawner.spawn_count -= 1 

##Find any battle scenes under battle root and gets rid of them
func clear_battle_scene()->void:
	for child in battle_root.get_children():
		if child is BattleScene:
			child.status_system.clear_battle_only_statuses()
			child.queue_free()
			await get_tree().process_frame
	pass
#endregion Battle




#region Helpers
#endregion Helpers
