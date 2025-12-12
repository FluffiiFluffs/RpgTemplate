@tool
class_name CurrentEquipButton
extends PanelContainer


@onready var button : Button = %Button
@onready var title_label : Label = %TitleLabel
@onready var equipment_label : Label = %EquipmentLabel

@export var equip_title : String = ""
@export var eq_item_type : String = ""

var equipment : Item = null

var is_active : bool = false


func _ready()->void:
	self_modulate = GameMenu.TRANS_COLOR
	title_label.text = equip_title
	button.focus_entered.connect(on_button_focus_entered)
	button.focus_exited.connect(on_button_focus_exited)
	button.pressed.connect(on_button_pressed)

	if Engine.is_editor_hint():
		return
	pass

#func on_button_pressed()->void:
	#GameMenu.make_equipping_buttons_list(return_item_type(eq_item_type))

func on_button_pressed() -> void:
	if GameMenu == null:
		return

	if GameMenu.menu_state == "EQUIP_MENU_REMOVE":
		GameMenu.remove_equipped_item(self)
		return

	# Treat both of these as "equip from this slot"
	if GameMenu.menu_state == "EQUIP_EQUIP_SELECT" or GameMenu.menu_state == "EQUIP_MENU_EQUIPPING":
		var eqtype = _get_eqtype_id()
		if eqtype == -1:
			return

		GameMenu.last_curr_equip_slot_button = self
		GameMenu.make_equipping_buttons_list(eqtype)
		return


func _get_eqtype_id() -> int:
	var key = eq_item_type.strip_edges().to_upper()
	match key:
		"WEAPON":
			return Item.ItemType.WEAPON
		"OFFHAND":
			return Item.ItemType.OFFHAND
		"HEAD":
			return Item.ItemType.HEAD
		"CHEST":
			return Item.ItemType.CHEST
		"ARMS":
			return Item.ItemType.ARMS
		"LEGS":
			return Item.ItemType.LEGS
		"ACCESSORY":
			return Item.ItemType.ACCESSORY
		_:
			printerr("CurrentEquipButton: unknown eq_item_type: " + eq_item_type)
			return -1


func on_button_focus_entered() -> void:
	self_modulate = GameMenu.ENABLED_COLOR

	if Engine.is_editor_hint():
		return
	if GameMenu == null:
		return

	# Allow preview refresh in both equip select and remove modes
	if GameMenu.menu_state != "EQUIP_EQUIP_SELECT" and GameMenu.menu_state != "EQUIP_MENU_REMOVE":
		return

	var eqtype = _get_eqtype_id()
	if eqtype == -1:
		return

	# In remove mode, if OFFHAND is mirroring MAINHAND due to two handing,
	# preview the weapon list instead of hiding the list.
	if GameMenu.menu_state == "EQUIP_MENU_REMOVE":
		var member: PartyMemberData = GameMenu.current_selected_party_member
		if member != null and eqtype == Item.ItemType.OFFHAND:
			if member.two_handing == true and member.mainhand != null:
				eqtype = Item.ItemType.WEAPON

		# Ensure no stale deltas remain visible while removing
		GameMenu.hide_all_equip_differences()

	GameMenu.equip_preview_owner = self
	GameMenu.make_equipping_buttons_list(eqtype, false)


	
func on_button_focus_exited()->void:
	if is_active:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.TRANS_COLOR
		
func grab_button_focus()->void:
	button.grab_focus()
