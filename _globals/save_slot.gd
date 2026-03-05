class_name SaveSlot extends PanelContainer

@onready var player_name_label: Label = %PlayerNameLabel
@onready var location_label: Label = %LocationLabel
@onready var money_amount: Label = %MoneyAmount
@onready var time_amount: Label = %TimeAmount
@onready var lv_amount: Label = %LvAmount
@onready var save_amount: Label = %SaveAmount
@onready var button: Button = %Button

## The actual save file from the file system being referenced for this slot
var save_file

var is_active : bool = false

var slot_number: int = 0
var has_save_file: bool = false

func _ready()->void:
	button.pressed.connect(on_button_pressed)
	button.focus_entered.connect(on_button_focused)
	button.focus_exited.connect(on_button_unfocused)

func on_button_pressed()->void:
	SaveManager.save_load_menu.on_slot_confirm(slot_number, has_save_file)

func on_button_focused()->void:
	SaveManager.save_load_menu.set_selected_save_slot(slot_number)
	self_modulate = GameMenu.ENABLED_COLOR

func on_button_unfocused()->void:
	if is_active:
		self_modulate = GameMenu.ENABLED_COLOR
	else:
		self_modulate = GameMenu.WHITE_COLOR

func grab_button_focus()->void:
	button.grab_focus()

func set_slot_number(new_slot_number: int) -> void:
	slot_number = new_slot_number

func set_has_save_file(new_has_save_file: bool) -> void:
	has_save_file = new_has_save_file

func set_button_disabled(is_disabled: bool) -> void:
	button.disabled = is_disabled

func set_player_name_label(_name : String)->void:
	player_name_label.text = _name

func set_location_label(_locname : String)->void:
	location_label.text = _locname

func set_money_amount(_amount : int)->void:
	money_amount.text = str(_amount)

func set_time_amount(time_text: String) -> void:
	time_amount.text = time_text

func set_lv_amount(_lv : int)->void:
	lv_amount.text = str(_lv)

func set_save_amount(_amount : int)->void:
	save_amount.text = str(_amount)

func apply_empty_slot() -> void:
	set_has_save_file(false)
	set_player_name_label("")
	set_location_label("")
	money_amount.text = ""
	set_time_amount("000:00:00")
	lv_amount.text = ""
	save_amount.text = ""
	is_active = false
	self_modulate = GameMenu.WHITE_COLOR
