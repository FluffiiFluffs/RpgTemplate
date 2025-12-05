##options.gd
##Global Script Options
extends Node2D


#region In-Game Options (for player)
@export_category("Volume")
##Music volume value
@export_range(0.0,10.0, 0.5) var music_volume : float = 7.0 : set = set_music_volume
##SFX volume value
@export_range(0.0,10.0, 0.5) var sfx_volume : float = 7.0 : set = set_sfx_volume
## Voices volume value
@export_range(0.0,10.0, 0.5) var voices_volume : float = 7.0 : set = set_voices_volume

@export_category("Item Sort Order")
##Inventory sort order. Pops up extra menu when button pressed
@export var item_sort_order : Array = ["HEAL","MPHEAL", "STATUSHEAL", "TOOL", "KEY", "EQUIPMENT"]

@export_category("Dialogue")
## 0 : FULL = Speaking characters play their voice sound rapidly.[br]
## 1 : START = Speaking characters only play their voices at the beginning of text.[br]
## 2 : OFF = Speaking characters do not make sound.
@export_enum("FULL", "START", "OFF") var voices_type : int = 0
## 0 : TALKING = Speaking character portraits fully animate.[br]
## 1 : STILL = Speaking character portraits do not animate (but will show expression).
@export_enum("TALKING", "STILL") var portrait_type : int = 1

@export_category("Movement")
@export var always_run : bool = false

@export_category("Message Speeds")
##message speed (need to make this a thing in dialogue manager)
@export var message_speed : float = 1.0 # : set = set_message_speed
##battle message speed
@export var battle_message_speed : float = 1.0  #: set = set_battle_message_speed

@export_category("Menu Memory")
##If the cursor position is remembered on main menus
@export var menu_memory : bool = false
##If the cursor position is remembered in battle menus (per character?)
@export var battle_menu_memory : bool = false


#current-game-stats (like how many enemies killed)
#menu colors/style
#controls



#endregion


#region Dev Options
#region Class-Specific colors
@export_category("Class Colors")
##DEV OPTION[br]Class color for Warrior
@export var class_color_warrior : Color = Color(0.485, 0.0, 0.0, 1.0)
##DEV OPTION[br]Class color for Thief
@export var class_color_thief : Color = Color(0.485, 0.349, 0.0, 1.0)
##DEV OPTION[br]Class color for mage
@export var class_color_mage : Color = Color(0.485, 0.0, 0.485, 1.0)
##DEV OPTION[br]Class color for healer
@export var class_color_healer : Color = Color(0.0, 0.485, 0.485, 1.0)
#endregion


#region Inventory Options
@export_category("INVENTORY")
##DEV OPTION[br]
##If true, another stack of the item will be made when it fills up
@export var multi_stacks : bool = true

#endregion

#endregion


#region Helper Functions

func _ready()->void:
	set_music_volume(music_volume)
	set_sfx_volume(sfx_volume)
	set_voices_volume(voices_volume)

func set_music_volume(_value: float) -> void:
	# clamp to slider range
	music_volume = clampf(_value, 0.0, 10.0)

	# normalize to 0.0–1.0
	var t := music_volume / 10.0

	# map 0.0–1.0 to dB range
	var db := lerpf(-40.0, 6.0, t)

	var bus := AudioServer.get_bus_index("Music")
	AudioServer.set_bus_volume_db(bus, db)
	print("Music DB : ", AudioServer.get_bus_volume_db(bus))
	
func set_sfx_volume(_value:float)->void:
	# clamp to slider range
	sfx_volume = clampf(_value, 0.0, 10.0)

	# normalize to 0.0–1.0
	var t := sfx_volume / 10.0

	# map 0.0–1.0 to dB range
	var db := lerpf(-40.0, 6.0, t)

	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_volume_db(bus, db)
	print("SFX DB : ", AudioServer.get_bus_volume_db(bus))
	
func set_voices_volume(_value:float)->void:
	# clamp to slider range
	voices_volume = clampf(_value, 0.0, 10.0)

	# normalize to 0.0–1.0
	var t := voices_volume / 10.0

	# map 0.0–1.0 to dB range
	var db := lerpf(-40.0, 6.0, t)

	var bus := AudioServer.get_bus_index("Voices")
	AudioServer.set_bus_volume_db(bus, db)
	print("Voices DB : ", AudioServer.get_bus_volume_db(bus))

func set_message_speed(_value:float)->void:
	pass
	
func set_battle_message_speed(_value:float)->void:
	pass
#endregion
