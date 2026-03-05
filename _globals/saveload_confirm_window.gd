#class_name SaveLoadConfirmWindow extends CanvasLayer
#
#
#@onready var confirm_label: Label = %ConfirmLabel
#@onready var no_button: Button = %NoButton
#@onready var yes_button: Button = %YesButton
#
#
#func _ready()->void:
	#visible = false
	#no_button.pressed.connect(no_button_pressed)
	#yes_button.pressed.connect(yes_button_pressed)
	#
	#
#func no_button_pressed()->void:
	#match SaveManager.save_load_menu.menu_mode:
		#SaveLoadMenu.MODE.SAVE or SaveLoadMenu.MODE.LOAD:
			#match SaveLoadMenu.SUB_MODE:
				#SaveLoadMenu.SUB_MODE.SAVE_CONFIRM:
					##hide confirm window
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
					##focus last save selected
					#pass
				#SaveLoadMenu.SUB_MODE.LOAD_CONFIRM:
					##hide confirm window
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
					##focus last save selected
					#pass
				#SaveLoadMenu.SUB_MODE.COPYING_CONFIRM:
					##hide confirm window
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
					##focus last save selected
					#pass
				#SaveLoadMenu.SUB_MODE.ERASE_CONFIRM:
					##hide confirm window
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
					##focus last save selected
					#pass
#
#func yes_button_pressed()->void:
	#match SaveManager.save_load_menu.menu_mode:
		#SaveLoadMenu.MODE.SAVE:
			#match SaveLoadMenu.SUB_MODE:
				#SaveLoadMenu.SUB_MODE.SAVE_CONFIRM:
					##save the game in the currently selected slot. overwrite it (user hit yes on confirm)
					##close saveloadmenu
					##return game to last game state (probably field)
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
				#SaveLoadMenu.SUB_MODE.LOAD_CONFIRM:
					## save menu is open so the sub_menu should never be in this state with that condition
					#pass
				#SaveLoadMenu.SUB_MODE.COPYING_CONFIRM:
					##copy the game from the originally selected save slot to the save slot selected to be copied to
					##hide confirm window
					##refresh the save game list
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.COPY # From COPY_CONFIRM
					## focus the slot that the savegame was copied FROM
					#
					#pass
				#SaveLoadMenu.SUB_MODE.ERASE_CONFIRM:
					##delete the save file from the file system
					##refresh the save game list
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.ERASE #from ERASE_CONFIRM
					## focus the empty savegame slot
		#SaveLoadMenu.MODE.LOAD:
			#match SaveLoadMenu.SUB_MODE:
				#SaveLoadMenu.SUB_MODE.SAVE_CONFIRM:
					##load menu is open so the sub_mode should never be in this state with that condition
					#pass
				#SaveLoadMenu.SUB_MODE.LOAD_CONFIRM:
					##hide saveloadmenu
					##hide confirm window
					##hide game menu, set to closed state
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.NONE
					## load the save game file from the currently selected save slot
					#pass
				#SaveLoadMenu.SUB_MODE.COPYING_CONFIRM:
					##copy the game from the originally selected save slot to the save slot selected to be copied to
					##hide confirm window
					##refresh the save game list
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.COPY # From COPY_CONFIRM
					## focus the slot that the savegame was copied FROM
					#
					#pass
				#SaveLoadMenu.SUB_MODE.ERASE_CONFIRM:
					##delete the save file from the file system
					##refresh the save game list
					#SaveManager.save_load_menu.sub_mode = SaveLoadMenu.SUB_MODE.ERASE #from ERASE_CONFIRM
					## focus the empty savegame slot
					#
					#pass
#
	#
	#


class_name SaveLoadConfirmWindow extends CanvasLayer

@onready var confirm_label: Label = %ConfirmLabel
@onready var no_button: Button = %NoButton
@onready var yes_button: Button = %YesButton

func _ready()->void:
	visible = false
	no_button.pressed.connect(_on_no_button_pressed)
	yes_button.pressed.connect(_on_yes_button_pressed)

func set_confirm_text(new_text: String) -> void:
	confirm_label.text = new_text

func focus_default_button() -> void:
	yes_button.grab_focus()

func _on_no_button_pressed() -> void:
	SaveManager.save_load_menu.on_confirm_cancelled()

func _on_yes_button_pressed() -> void:
	SaveManager.save_load_menu.on_confirm_accepted()
