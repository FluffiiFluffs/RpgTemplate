class_name SaveLoadConfirmWindow extends CanvasLayer

@onready var confirm_label: Label = %ConfirmLabel
@onready var no_button: Button = %NoButton
@onready var yes_button: Button = %YesButton

var accept_callback: Callable = Callable()
var cancel_callback: Callable = Callable()

func _ready()->void:
	visible = false
	no_button.pressed.connect(_on_no_button_pressed)
	yes_button.pressed.connect(_on_yes_button_pressed)

func set_confirm_text(new_text: String) -> void:
	confirm_label.text = new_text

func open_confirm(
	new_text: String,
	on_accept: Callable = Callable(),
	on_cancel: Callable = Callable()
) -> void:
	accept_callback = on_accept
	cancel_callback = on_cancel
	confirm_label.text = new_text
	visible = true

func close_confirm() -> void:
	visible = false
	clear_callbacks()

func clear_callbacks() -> void:
	accept_callback = Callable()
	cancel_callback = Callable()

func focus_default_button() -> void:
	yes_button.grab_focus()

func focus_no_button() -> void:
	no_button.grab_focus()

func _on_no_button_pressed() -> void:
	visible = false

	if cancel_callback.is_valid():
		var callback: Callable = cancel_callback
		clear_callbacks()
		callback.call()
		return

	clear_callbacks()
	SaveManager.save_load_menu.on_confirm_cancelled()

func _on_yes_button_pressed() -> void:
	visible = false

	if accept_callback.is_valid():
		var callback: Callable = accept_callback
		clear_callbacks()
		callback.call()
		return

	clear_callbacks()
	SaveManager.save_load_menu.on_confirm_accepted()
