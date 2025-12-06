@tool
class_name TopLevelStats
extends Control
##Box used to show Name/Level/HP/MP/Buffs of a party member at a quick glance




##Styleboxflat border color property can be accessed to show party member's unique color
@onready var stats_container : PanelContainer = %StatsContainer
##Text property should be set to the appropriate party member's name from CharDataKeeper
@onready var char_name_label : Label = %CharNameLabel
##Styleboxflat border color property can be accessed to show party member's unique color
@onready var hp_panel_container : PanelContainer = %HPPanelContainer
##max_value and value should be set to match the party member's current amounts
@onready var hp_progress_bar : ProgressBar = %HPProgressBar
##Styleboxflat border color property can be accessed to show party member's unique color
@onready var mp_panel_container : PanelContainer = %MPPanelContainer
##max_value and value should be set to match the party member's current amounts
@onready var mp_progress_bar : ProgressBar = %MPProgressBar
##Animationplayer for playing flash animation on top border.
@onready var top_animation_player : AnimationPlayer = %TopAnimationPlayer
##Shows current buffs 16x16
@onready var buff_texture : TextureRect = %BuffTexture
##Shows current debuffs 16x16
@onready var debuff_texture : TextureRect = %DebuffTexture





##Button used to confirm selection on this pane
@onready var button = %Button #toggle mode enabled
@onready var top_flasher_container = %TopFlasherContainer

##Reference to party member in CharDataKeeper
var party_member : PartyMemberData
var is_selected : bool = false 
var is_disabled : bool = false #used to let the other UI elements know something cannot be used on this party member
var class_color : Color = Options.class_color_warrior

const FLASH_COLOR1 : Color = Color("ff24bbff")
const FLASH_COLOR2 : Color = Color(1.0, 0.0, 0.0, 1.0)
const OFF_COLOR : Color = Color(0.0, 0.0, 0.0, 0.0)
##use GameMenu.DISABLED_COLOR for disabled color
const DEAD_COLOR : Color = Color(0.185, 0.097, 0.093, 1.0)

func _ready() -> void:
	button.pressed.connect(on_button_pressed)
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	
	if Engine.is_editor_hint():
		return
	top_flasher_container.visible = true #hidden in the editor because it blocks stuff, but needs to be visible otherise
	pass
	
func grab_button_focus()->void:
	button.grab_focus()	

func on_button_pressed()->void:
	#maybe send a signal to let the UI know the item was used. maybe needs to be setup a different way. unsure
	pass
	
func on_button_focus_entered()->void:
	#only if item being used is valid
	top_animation_player.play("flash_top")
	pass
	
func on_button_focus_exited()->void:
	##stop all animation players so colors go back to normal
	top_animation_player.stop()
	##determine go back to the original color (either dead or class color)
	
	pass
	
	
	
##Stores reference to class color of the character this scene belongs to
func set_class_color(_color:Color)->void:
	class_color = _color

##Sets the border color of top,hp,mp to a specific color
func border_color_change(_color : Color) ->void:
	stats_container.self_modulate = _color
	hp_panel_container.self_modulate = _color
	mp_panel_container.self_modulate = _color


func set_border_color_when_dead()->void:
	border_color_change(DEAD_COLOR)
	pass

##Sets border color to class color
func set_border_color_to_class()->void:
		if class_color == null:
			border_color_change(GameMenu.WHITE_COLOR)
		else:
			border_color_change(class_color)
	
##makes the border color the disabled color, use set_border_color() to revert back to normal
func set_border_color_to_disable()->void:
	border_color_change(GameMenu.DISABLED_COLOR)
	

func set_top_border_flash()->void:
	top_animation_player.play("flash_top")
	
func set_hp_border_flash()->void:
	pass

func set_mp_border_flash()->void:
	pass



##TODO
func update_buffs()->void:
	##check partymemberdata corresponding to this window
	##update buff hbox graphics
	##graphics should or should not show corresponding with whatever buffs are active
	pass
