@tool
class_name TopLevelStats
extends Control
##Box used to show Name/Level/HP/MP/Buffs of a party member at a quick glance

@onready var stats_container : PanelContainer = %StatsContainer
@onready var char_name_label : Label = %CharNameLabel
@onready var hp_panel_container : PanelContainer = %HPPanelContainer
@onready var hp_progress_bar : ProgressBar = %HPProgressBar
@onready var mp_panel_container : PanelContainer = %MPPanelContainer
@onready var mp_progress_bar : ProgressBar = %MPProgressBar
@onready var top_animation_player : AnimationPlayer = %TopAnimationPlayer
@onready var buff_texture : TextureRect = %BuffTexture
@onready var debuff_texture : TextureRect = %DebuffTexture

@onready var button = %Button
@onready var top_flasher_container = %TopFlasherContainer

var party_member : PartyMemberData
var is_selected : bool = false
var is_disabled : bool = false   # no longer used for visuals
var class_color : Color = Options.class_color_warrior

const FLASH_COLOR1 : Color = Color("ff24bbff")
const FLASH_COLOR2 : Color = Color(1.0, 0.0, 0.0, 1.0)
const OFF_COLOR : Color = Color(0.0, 0.0, 0.0, 0.0)
const DEAD_COLOR : Color = Color(0.185, 0.097, 0.093, 1.0)

func _ready() -> void:
	button.pressed.connect(on_button_pressed)
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	
	if Engine.is_editor_hint():
		return
	top_flasher_container.visible = true

func grab_button_focus()->void:
	button.grab_focus()	
func on_button_pressed()->void:
	if Engine.is_editor_hint():
		return

	if GameMenu.menu_state != "USE_ITEMS_USING":
		return

	var inv_button = GameMenu.last_selected_inventory_button
	if inv_button == null:
		GameMenu.play_error_sound()
		return

	var slot = inv_button.islot
	if slot == null or slot.item == null:
		GameMenu.play_error_sound()
		return

	var item : Item = slot.item

	var any_effect_applied = false
	for effect in item.effects:
		if effect == null:
			continue
		if effect.apply_to_member(party_member):
			any_effect_applied = true

	if not any_effect_applied:
		return

	# Where was this slot in the inventory list before we change it
	var original_index = Inventory.current_inventory.find(slot)

	if item.one_less_on_use:
		slot.quantity -= 1

		if slot.quantity <= 0:
			# Remove the slot from the data
			Inventory.current_inventory.erase(slot)
			GameMenu.last_selected_inventory_button = null

			# Rebuild UI and stats
			GameMenu.update_items_list()
			GameMenu.update_top_level_stats_box(self)

			var new_count = Inventory.current_inventory.size()
			GameMenu.menu_state = "USE_ITEMS"

			if new_count > 0:
				if original_index < 0:
					original_index = 0
				if original_index >= new_count:
					original_index = new_count - 1

				# Focus neighbor item according to the original position
				GameMenu.focus_inventory_item_index(original_index)
			else:
				# No items left, fall back to the inventory options row
				GameMenu.focus_inventory_options()

			return
		else:
			if GameMenu.last_selected_inventory_button != null:
				GameMenu.last_selected_inventory_button.item_qty_label.text = str(slot.quantity)

	GameMenu.update_top_level_stats_box(self)



func on_button_focus_entered()->void:
	if Engine.is_editor_hint():
		return

	# no more “disabled” visuals or item checks here
	is_disabled = false
	set_top_border_flash()


func on_button_focus_exited()->void:
	# simply stop the flash, leave border color alone
	top_animation_player.stop()
	is_disabled = false


func set_class_color(_color:Color)->void:
	class_color = _color

func border_color_change(_color : Color) ->void:
	stats_container.self_modulate = _color
	hp_panel_container.self_modulate = _color
	mp_panel_container.self_modulate = _color

func set_border_color_when_dead()->void:
	border_color_change(DEAD_COLOR)

func set_border_color_to_class()->void:
	if class_color == null:
		border_color_change(GameMenu.WHITE_COLOR)
	else:
		border_color_change(class_color)

func set_border_color_to_disable()->void:
	border_color_change(GameMenu.DISABLED_COLOR)

func set_top_border_flash()->void:
	top_animation_player.play("flash_top")

func update_buffs()->void:
	pass
