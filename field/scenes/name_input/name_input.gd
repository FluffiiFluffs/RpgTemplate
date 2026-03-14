class_name NameInput
extends CanvasLayer
## How this should work
## A character needs to be named.
	## Main character should always be named in the beginning of the game
	## Other characters may be named at the beginning of the game (mother style) or when they are introduced (FF6 style)
## The naming scene should be instantiated into main.overscene so it doesn't interfere with a field scene (during gameplay)
## Input in the field scene should be taken away and input switches to the naming scene
	## gamestate naming should be used for this
## The character to be named should be found using the actor_id from CharDataKeeper.all_party_members array (which is pre-populated)
	## This needs to be orchestrated with a scenemanager function that awaits the naming scene load, and then calls load_member_by_id() when it's loaded. 
		## This the function to do this in scenemanager can be called by dialogue or a cutscene action (which provides the ID).
	## party member data should be duplicated from all party members so the source isn't touched
## Naming scene should clear children of fieldspritemarker and then instantiate the party member being named as a child of the marker
##  The gender of the party member should be done first (hide gender label and gender grid, show input letter h box and letter grid)
	## Default gender focused should be male for the sake of simplicity (not really a bias, but the focus needs to start somewhere)
	## gender label should start out blank ""
	## Questionlabel should simply say "Gender?" (maybe need a better way to pose this, but figure it out later)
	## PickForMe picks a random gender for the character (random 0-3 value and then pick a gender)
	## Reset button should be hidden during this phase
	## Next records the selected gender to the party member data file that was duplicated from all_party_members 
		## puts scene into naming state (from genderpick state)
## When naming state is called
	## gender label is hidden and gendergrid is hidden
	## input letter h box is shown and letter grid is shown
		## input letter objects are instantiated so that name_max_length can define how many letters a name can be	
		## first letter in the grid is focused (probably A)
	## All letters in input letter h box is cleared to be blank
	## Reset button is shown
		## Reset button simply completely clears all input letters to ""
	##PickForMe button being pressed now cycles through all possible names defined within the party member data's possible name field (also needs to return if there are none defined so we don't crash during testing). Should loop around from last to first. Needs to work for as many names as there are in the array (whether there be a few or many)
	## Next button should shows confirmation control
		## party member's field sprite is instantiated as a child of fieldspritemarkerconfirmation
		## genderlabelconfirm propagated with the selected gender
		## namelabelconfirm propagated with name selected
	## NoConfirm takes player back to the naming phase
		## hitting cancel button also does this
	## YesConfirm sets the gender and displayed name in current_member_data.
		## Current member data then put into CharDataKeeper.party_members via duplicate(true)
	## Scene then continues to the next thing
		## if it's the beginning of the game...the first character's info is registered, so it load the opening scene of the game
		## if this input is happening during the game, then it should queue free and gameplay should continue (probably during dialogue or a cutscene so this needs to be figured out).
		
		
enum NISTATE{GENDER, NAMING, CONFIRM}
		
## Displays the large portrait of the character
@onready var stats_portrait: TextureRect = %StatsPortrait

## Contains all the letters / symbols that can be input for names
@onready var letter_grid: GridContainer = %LetterGrid

## HBox containing the input letters for a name
@onready var input_letter_h_box: HBoxContainer = %InputLetterHBox

## Gridcontainer containing gender options
@onready var gender_grid: GridContainer = %GenderGrid

## Label showing different pronoun states of each gender choice.
@onready var gender_label: Label = %GenderLabel

## Like the Dont know button in earthbound/mother3
@onready var pick_for_me: Button = %PickForMe
## Clears name or gender
@onready var reset: Button = %RESET

## Goes to the next phase
@onready var next: Button = %Next



@onready var field_sprite_marker: Marker2D = %FieldSpriteMarker

## Used to control overall visibility of gender/naming 
@onready var name_gender_control: Control = %NameGenderControl
@onready var question_label: Label = %QuestionLabel

## Used to control visibility of the confirmation window
@onready var confirmation_control: Control = %ConfirmationControl
@onready var field_sprite_marker_confirm: Marker2D = %FieldSpriteMarkerConfirm
@onready var gender_label_confirm: Label = %GenderLabelConfirm
@onready var name_label_confirm: Label = %NameLabelConfirm
@onready var no_confirm: Button = %NoConfirm
@onready var yes_confirm: Button = %YesConfirm
@onready var he_button: GenderButton = %HE
@onready var a_button: LetterEntryButton = %A
@onready var back_button: Button = %Back


## Current party member's name being input
@export var current_member_data : PartyMemberData = null

## 8 Characters is the max the UI can handle.
var name_max_length : int = 8
var current_input_letter_place : int = 0
var current_possible_name_index : int = 0
var selected_gender : int = -1
var selected_name : String = ""
var state : NISTATE
var previous_gamestate : int = GameState.State.STARTMENU
var target_actor_id : StringName = &""
var _scene_is_ready : bool = false
var _did_start : bool = false

const INPUT_LETTER = preload("uid://cos3t0ctsf8g0")

signal overscene_completed(should_abort_cutscene : bool)

func _ready()->void:
	reference_self_to_letters()
	setup_gendergrid_buttons()
	pick_for_me.pressed.connect(on_pick_for_me_button_pressed)
	reset.pressed.connect(on_reset_button_pressed)
	next.pressed.connect(on_next_button_pressed)
	no_confirm.pressed.connect(on_no_confirm_button_pressed)
	yes_confirm.pressed.connect(on_yes_confirm_button_pressed)
	back_button.pressed.connect(on_back_button_pressed)

	back_button.visible = false

	_scene_is_ready = true
	_try_start_from_overscene()
	
## Loads a party member called by actor_id. Should be called with a custom script.
func load_member_by_id(id : StringName) -> bool:
	current_member_data = null
	current_input_letter_place = 0
	current_possible_name_index = 0
	selected_gender = -1
	selected_name = ""

	if id == &"":
		return false

	for pm in Registry.all_party_members:
		if id == pm.actor_id:
			current_member_data = pm.duplicate(true) as PartyMemberData
			if current_member_data.speaker_resource != null:
				current_member_data.speaker_resource = current_member_data.speaker_resource.duplicate(true)
			return true

	return false
	
func apply_cutscene_overscene_action(action : CutsceneOverscene) -> void:
	if action == null:
		return

	target_actor_id = action.actor_id
	_try_start_from_overscene()


func _try_start_from_overscene() -> void:
	if _scene_is_ready == false:
		return
	if _did_start == true:
		return

	previous_gamestate = GameState.gamestate
	GameState.gamestate = GameState.State.NAMING

	if load_member_by_id(target_actor_id) == false:
		push_error("NameInput: actor_id not found in Registry.all_party_members: " + String(target_actor_id))
		_finish_overscene()
		return

	_did_start = true
	setup_portraits()
	call_deferred("ready_gender_input")


func _finish_overscene(should_abort_cutscene : bool = false) -> void:
	GameState.gamestate = previous_gamestate
	overscene_completed.emit(should_abort_cutscene)
	
## Begins naming routine
func start()->void:
	setup_portraits()
	await get_tree().process_frame
	ready_gender_input()
	
func setup_portraits()->void:
	stats_portrait.texture = current_member_data.stats_sprite
	clear_field_sprite()

	var field_sprite : FieldPartyMember = current_member_data.field_scene.instantiate()
	field_sprite_marker.add_child(field_sprite)

	var confirm_field_sprite : FieldPartyMember = current_member_data.field_scene.instantiate()
	field_sprite_marker_confirm.add_child(confirm_field_sprite)
	
func clear_field_sprite()->void:
	for child in field_sprite_marker.get_children():
		child.queue_free()
	for child in field_sprite_marker_confirm.get_children():
		child.queue_free()

func ready_gender_input()->void:
	state = NISTATE.GENDER
	selected_gender = -1
	selected_name = ""
	confirmation_control.visible = false
	name_gender_control.visible = true
	input_letter_h_box.visible = false
	letter_grid.visible = false
	gender_grid.visible = true
	gender_label.visible = true
	reset.visible = false
	gender_label.text = ""
	question_label.text = "Gender?"
	_update_back_button_visibility()

	for child in gender_grid.get_children():
		if child is GenderButton:
			child.is_active = false
	he_button.button.grab_focus()

## This is done after the the sequence ends.
## This is done after the the sequence ends.
func place_party_member_into_party(place : int) -> void:
	if current_member_data == null:
		return

	var member_copy : PartyMemberData = current_member_data.duplicate(true) as PartyMemberData
	if member_copy.speaker_resource != null:
		member_copy.speaker_resource = member_copy.speaker_resource.duplicate(true)

	# Build level based base stats from StatsTable for this runtime copy.
	member_copy.rebuild_base_stats()

	# New party members added through naming should enter with fresh vitals
	# matching their current level derived max values.
	member_copy.current_hp = member_copy.get_max_hp()
	member_copy.current_sp = member_copy.get_max_sp()

	# Keep next level threshold in sync for the added member.
	CharDataKeeper.refresh_next_level_exp_for_member(member_copy)

	if place == 0:
		CharDataKeeper.add_party_member(member_copy)
	else:
		CharDataKeeper.outside_members.append(member_copy)

func ready_name_input()->void:
	state = NISTATE.NAMING
	current_input_letter_place = 0
	selected_name = ""
	clear_input_letter_box()
	propagate_blank_input_letter_box()
	confirmation_control.visible = false
	name_gender_control.visible = true
	input_letter_h_box.visible = true
	reset.visible = true
	letter_grid.visible = true
	gender_grid.visible = false
	gender_label.visible = false
	question_label.text = "Name?"
	_update_back_button_visibility()
	a_button.grab_focus()


func reference_self_to_letters()->void:
	for child in letter_grid.get_children():
		if child is LetterEntryButton:
			child.input_scene = self

## Clears the input letter h box
func clear_input_letter_box()->void:
	for child in input_letter_h_box.get_children():
		child.free()

## Called AFTER the question for what to be named has been added		
func propagate_blank_input_letter_box()->void:
	for i in name_max_length:
		var new_letter : InputLetter = INPUT_LETTER.instantiate()
		input_letter_h_box.add_child(new_letter)
		
## Called when a LetterEntryButton is pressed. Puts the letter kept within LetterEntryButton into the current place (InputLetter)
func apply_letter(_letter : String)->void:
	var namebox : Array = input_letter_h_box.get_children()
	if namebox.is_empty():
		return
	if current_input_letter_place >= namebox.size():
		return

	var input_letter : InputLetter = namebox[current_input_letter_place]
	input_letter.letter = _letter
	current_input_letter_place += 1
	
func backspace()->void:
	var namebox : Array = input_letter_h_box.get_children()
	if namebox.is_empty():
		return

	current_input_letter_place -= 1
	if current_input_letter_place < 0:
		current_input_letter_place = 0

	var input_letter : InputLetter = namebox[current_input_letter_place]
	input_letter.letter = ""
	
func reset_input_letters()->void:
	current_input_letter_place = 0
	for child in input_letter_h_box.get_children():
		if child is InputLetter:
			child.letter = ""
	pass

func setup_gendergrid_buttons()->void:
	for child in gender_grid.get_children():
		if child is GenderButton:
			var gender_button : GenderButton = child
			gender_button.button.pressed.connect(
				func() -> void:
					for grid_child in gender_grid.get_children():
						if grid_child is GenderButton:
							grid_child.is_active = false
					gender_button.is_active = true
					selected_gender = gender_button.gender
					set_gender_label(gender_button.gender)
			)

func set_gender_label(_num : int)->void:
	match _num:
		0:
			gender_label.text = "HE / HIM / HIS/ HIS / HIMSELF"
			pass
		1:
			gender_label.text = "SHE / HER / HER / HERS / HERSELF"
			pass
		2:
			gender_label.text = "THEY / THEM / THEIR / THEIRS / THEMSELF"
			pass
		3:
			gender_label.text = "IT / IT / ITS / ITS / ITSELF"
			pass


## Goes down a list of names that are predefined per party member if in the naming phase
## Picks a random gender for the player if in that phase
## Does not pick randomly
func on_pick_for_me_button_pressed()->void:
	match state:
		NISTATE.GENDER:
			selected_gender = randi_range(0, 3)

			for child in gender_grid.get_children():
				if child is GenderButton:
					child.is_active = child.gender == selected_gender

			set_gender_label(selected_gender)

		NISTATE.NAMING:
			var new_name : String = get_possible_party_member_name()
			if new_name == "":
				return

			reset_input_letters()

			var letters_to_apply : int = min(name_max_length, new_name.length())
			for i in letters_to_apply:
				apply_letter(new_name.substr(i, 1))

		NISTATE.CONFIRM:
			return

## Resets current name to be blank
## Resets current gender to be blank
## Not a full start-over, just for the current phase
func on_reset_button_pressed()->void:
	match state:
		NISTATE.GENDER:
			selected_gender = -1
			gender_label.text = ""
			for child in gender_grid.get_children():
				if child is GenderButton:
					child.is_active = false

		NISTATE.NAMING:
			selected_name = ""
			reset_input_letters()

		NISTATE.CONFIRM:
			return
	
## Advances the name input to the next stage
## character introduction > gender > naming > confirm (puts character into party if not over max party members)
func on_next_button_pressed() -> void:
	match state:
		NISTATE.GENDER:
			if selected_gender == -1:
				return

			current_member_data.gender = selected_gender
			if current_member_data.speaker_resource != null:
				@warning_ignore("int_as_enum_without_cast")
				current_member_data.speaker_resource.pronoun = selected_gender
			ready_name_input()

		NISTATE.NAMING:
			parse_and_apply_name()
			if selected_name == "":
				return

			name_gender_control.visible = false
			confirmation_control.visible = true
			gender_label_confirm.text = gender_label.text
			name_label_confirm.text = selected_name
			state = NISTATE.CONFIRM
			_update_back_button_visibility()
			no_confirm.grab_focus()

		NISTATE.CONFIRM:
			return
			
func on_no_confirm_button_pressed() -> void:
	if state != NISTATE.CONFIRM:
		return

	confirmation_control.visible = false
	name_gender_control.visible = true
	ready_name_input()

func on_yes_confirm_button_pressed() -> void:
	if state != NISTATE.CONFIRM:
		return

	current_member_data.gender = selected_gender
	current_member_data.display_name = selected_name

	if current_member_data.speaker_resource != null:
		@warning_ignore("int_as_enum_without_cast")
		current_member_data.speaker_resource.pronoun = selected_gender
		current_member_data.speaker_resource.display_name = selected_name

	place_party_member_into_party(0)
	_finish_overscene()
	
	
func _is_title_flow() -> bool:
	if SceneManager.main_scene == null:
		return false
	if SceneManager.main_scene.title_scene == null:
		return false
	return true


func _update_back_button_visibility() -> void:
	match state:
		NISTATE.GENDER:
			back_button.visible = _is_title_flow()

		NISTATE.NAMING:
			back_button.visible = true

		NISTATE.CONFIRM:
			back_button.visible = false
	
## If the last screen was the title scene, then take back to that
## If the naming scene was made mid-game, then hide the back button in this stage
	## In this case, the button should only been shown in the naming screen to go back to gender selection
func on_back_button_pressed()->void:
	match state:
		NISTATE.GENDER:
			if _is_title_flow():
				_finish_overscene(true)

		NISTATE.NAMING:
			ready_gender_input()

		NISTATE.CONFIRM:
			return
	
func get_possible_party_member_name()->String:
	if current_member_data == null:
		return ""

	if current_member_data.possible_names.is_empty():
		return ""

	if current_possible_name_index >= current_member_data.possible_names.size():
		current_possible_name_index = 0

	var result : String = current_member_data.possible_names[current_possible_name_index]
	current_possible_name_index += 1
	return result
	
	
func parse_and_apply_name() -> void:
	var namearray: Array[String] = []
	for child in input_letter_h_box.get_children():
		if child is InputLetter:
			namearray.append(child.letter)

	var finalname: String = ""
	for letter in namearray:
		finalname += letter

	selected_name = finalname.strip_edges()

func apply_name_party_member_action(action : CutsceneNamePartyMember) -> void:
	if action == null:
		return

	target_actor_id = action.actor_id
	_try_start_from_overscene()


func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("cancel_input"):
		if state == NISTATE.CONFIRM:
			on_no_confirm_button_pressed()
