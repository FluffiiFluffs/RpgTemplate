## CutsceneMarker.gd
## Authoring notes:
## The node name is the stable marker identifier referenced by cutscenes.
## Exports exist for filtering and validation, not identity.

@tool
class_name CutsceneMarker
extends Marker2D

@onready var sprite_2d: Sprite2D = %Sprite2D
@onready var control: Control = %Control
@onready var purpose_label: Label = %PurposeLabel
@onready var title_label: Label = %TitleLabel


@export var marker_id : StringName = &""
@export_multiline var description : String = ""


enum Purpose{
	GENERIC,
	NPC_MOVE_MARKER,
	CAMERA_MOVE_MARKER,
	SPAWN_POINT,
	}

@export var purpose : Purpose = Purpose.GENERIC
@export var show_in_game : bool = false

const RED_COLOR := Color(1.0, 0.0, 0.0, 1.0)
const ORANGE_COLOR := Color(1.0, 0.463, 0.0, 1.0)
const YELLOW_COLOR := Color(1.0, 1.0, 0.0, 1.0)
const GREEN_COLOR := Color(0.0, 1.0, 0.0, 1.0)
const BLUE_COLOR := Color(0.0, 0.0, 1.0, 1.0)
const INDIGO_COLOR := Color(0.613, 0.0, 0.898, 1.0)
const BLACK_COLOR := Color(0.0, 0.0, 0.0, 1.0)
const WHITE_COLOR := Color(1.0, 1.0, 1.0, 1.0)



func _ready()->void:
	if Engine.is_editor_hint():
		return
	if !show_in_game:
		control.queue_free()
		sprite_2d.queue_free()

func _process(_delta : float)->void:
	set_marker_id()
	if Engine.is_editor_hint():
		if title_label:
			set_title_label()
		if purpose_label:
			set_purpose_label()
		if sprite_2d:
			set_color()
		return
	if show_in_game:
		if title_label:
			set_title_label()
		if purpose_label:
			set_purpose_label()
		if sprite_2d:
			set_color()

func set_title_label()->void:
	title_label.text = name


func set_color()->void:
	var color := WHITE_COLOR
	match purpose:
		Purpose.GENERIC:
			color = WHITE_COLOR
		Purpose.NPC_MOVE_MARKER:
			color = GREEN_COLOR
		Purpose.CAMERA_MOVE_MARKER:
			color = ORANGE_COLOR
		Purpose.SPAWN_POINT:
			color = INDIGO_COLOR
	sprite_2d.modulate = color
	
func set_purpose_label()->void:
	var labeltext := ""
	match purpose:
		Purpose.GENERIC:
			labeltext = "GENERIC"
		Purpose.NPC_MOVE_MARKER:
			labeltext = "NPC_MOVE"
		Purpose.CAMERA_MOVE_MARKER:
			labeltext = "CAMERA_MOVE"
		Purpose.SPAWN_POINT:
			labeltext = "SPAWN_POINT"
	purpose_label.text = labeltext
	
func set_marker_id()->void:
	marker_id = name
