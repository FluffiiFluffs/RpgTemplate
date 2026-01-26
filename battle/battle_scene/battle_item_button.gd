class_name BattleItemButton
extends PanelContainer

@onready var label : Label = %Label
@onready var button : Button = %Button
@onready var qty_label : Label = %QtyLabel

##Reference to an item resource. Setup on instantiation.
var itemslot : InventorySlot = null #maybe this should be a reference to the item slot instead?
##Reference to the battler. Setup on instantiation.
var battler : Battler = null

##Makes border stay lit up when focus is lost (when the button is pressed)
var is_active : bool = false

func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	button.focus_entered.connect(button_focused)
	button.focus_exited.connect(button_unfocused)
	button.pressed.connect(button_pressed)

func button_focused()->void:
	self_modulate = GameMenu.ENABLED_COLOR
	show_description()
	pass

func button_unfocused()->void:
	if is_active:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
		hide_description()
	pass

func button_pressed()->void:
	if battler == null:
		printerr(name + " NO BATTLER SET!")
		queue_free()
		return
	if itemslot == null:
		printerr(name + " NO SKILL SET!")
		queue_free()
	if itemslot != null and battler != null:
		is_active = true 
		battler.ui_element.last_item_selected = itemslot
		(battler.ui_element as BattleStats).last_item_button_selected = self
		SceneManager.main_scene.current_battle_scene.command_controller.begin_use_item(battler, itemslot)

##Grabs the button's focus
func grab_button_focus()->void:
	button.grab_focus()

##Should be called after ready just to be safe. Makes label name and quantity
func setup()->void:
	label.text = itemslot.item.name
	qty_label.text = str(itemslot.quantity)

##Displays description of the skill through the notify UI
func show_description()->void:
	var battle_scene : BattleScene = SceneManager.main_scene.current_battle_scene
	battle_scene.battle_notify_ui.show_text(itemslot.item.description)
	pass

##Hides the notify UI
func hide_description()->void:
	var battle_scene : BattleScene = SceneManager.main_scene.current_battle_scene
	battle_scene.battle_notify_ui.notify_hide()
