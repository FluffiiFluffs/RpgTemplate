## global script "DM", dm_helper.gd
extends Node
## Speaker registry and dialogue presentation resolver.
## Owns speaker lookup, mood resolution, portrait resolution, voice fallback, pitch fallback,
## and active dialogue context state.

#region Configuration

const SPEAKER_DIR_PATH : String = "res://dialogue/speaker_resources"
const DEFAULT_VOICE_STREAM : AudioStream = preload("uid://dr3xptfehm82e") # snd_txtber

## Fallback voice used when a SpeakerResource has no voice assigned, or speaker_id is unknown.
var default_voice : AudioStream = DEFAULT_VOICE_STREAM

#endregion

#region Speaker registry


## All SpeakerResource assets that DM can resolve by speaker_id.
var all_speakers : Array[SpeakerResource] = []

## Internal index for fast lookup.
var _speaker_by_id : Dictionary = {} # StringName -> SpeakerResource

## Optional speaker overrides for the currently active dialogue run.
## These take precedence over the global registry and allow a caller to supply
## temporary SpeakerResource instances without touching the on disk registry.
var _run_speaker_by_id : Dictionary = {} # StringName -> SpeakerResource
#endregion

#region Active dialogue session state

## Currently active balloon node. Project policy assumes one active balloon at a time.
var active_balloon : Node = null

## Resource for the currently active dialogue run.
## Used so forced cleanup paths can still end the dialogue session deterministically.
var _active_dialogue_resource : Resource = null

## True after DialogueManager.dialogue_started until the session is finalized.
var _dialogue_session_active : bool = false

## True after DialogueManager.dialogue_ended (or after forced cleanup marks the session ended).
## Session is finalized only after the balloon is cleared/invalidated.
var _dialogue_end_received : bool = false

## Current active speaker context for the most recent DialogueLine.
var active_speaker_id : StringName = &""
var active_mood : StringName = &"normal"
var active_speaker : SpeakerResource = null

## Cached resolved presentation values for the active context.
var active_display_name : String = ""
var active_portrait_close : Texture2D = null
var active_portrait_open : Texture2D = null
var active_voice_stream : AudioStream = DEFAULT_VOICE_STREAM
var active_pitch_min : float = 1.0
var active_pitch_max : float = 1.0

signal dialogue_session_started(resource : Resource)
signal dialogue_session_ended(resource : Resource)


#endregion

#region Boot

func _ready() -> void:
	rebuild_speaker_registry(SPEAKER_DIR_PATH)

	# Dialogue session lifecycle.
	DialogueManager.dialogue_started.connect(_on_dialogue_started)
	DialogueManager.got_dialogue.connect(_on_got_dialogue)
	DialogueManager.dialogue_ended.connect(_on_dialogue_ended)

#endregion

#region Public API
func rebuild_speaker_registry(dir_path : String = SPEAKER_DIR_PATH) -> void:
	all_speakers.clear()
	_speaker_by_id.clear()

	var directory : DirAccess = DirAccess.open(dir_path)
	if directory == null:
		push_error("DM: speaker dir missing: " + dir_path)
		return

	directory.list_dir_begin()
	while true:
		var file_name : String = directory.get_next()
		if file_name.is_empty():
			break
		if directory.current_is_dir():
			continue
		if not (file_name.ends_with(".tres") or file_name.ends_with(".res")):
			continue

		var full_path : String = dir_path.path_join(file_name)
		var loaded_resource : Resource = load(full_path)
		var speaker : SpeakerResource = loaded_resource as SpeakerResource
		if speaker == null:
			continue

		_register_speaker(speaker)

	directory.list_dir_end()

func find_speaker_by_id(id) -> SpeakerResource:
	var key : StringName = _to_speaker_key(id)
	if key == &"":
		return null

	if _run_speaker_by_id.has(key):
		return _run_speaker_by_id[key]

	var runtime_party_speaker : SpeakerResource = _find_runtime_party_speaker_by_actor_id(key)
	if runtime_party_speaker != null:
		return runtime_party_speaker

	if _speaker_by_id.has(key):
		return _speaker_by_id[key]

	return null


func sname(speaker_id) -> String:
	var resolved_speaker : SpeakerResource = _resolve_inline_speaker_resource(speaker_id)
	if resolved_speaker != null:
		if not resolved_speaker.display_name.is_empty():
			return resolved_speaker.display_name
		if not resolved_speaker.speaker_id.is_empty():
			return resolved_speaker.speaker_id

	var fallback_id : StringName = _to_speaker_key(speaker_id)
	if fallback_id == &"":
		return ""
	return String(fallback_id)

## Pronoun
func pn(speaker_id, pronoun_type : int) -> String:
	var resolved_speaker : SpeakerResource = _resolve_inline_speaker_resource(speaker_id)
	if resolved_speaker == null:
		return ""

	if pronoun_type < 1 or pronoun_type > 5:
		push_warning("DM: pn pronoun_type must be 1 through 5. Got: %s" % str(pronoun_type))
		return ""

	var pronoun_forms : PackedStringArray = PackedStringArray()

	match resolved_speaker.pronoun:
		SpeakerResource.GENDER.HE:
			pronoun_forms = PackedStringArray(["he", "him", "his", "his", "himself"])
		SpeakerResource.GENDER.SHE:
			pronoun_forms = PackedStringArray(["she", "her", "her", "hers", "herself"])
		SpeakerResource.GENDER.THEY:
			pronoun_forms = PackedStringArray(["they", "them", "their", "theirs", "themselves"])
		SpeakerResource.GENDER.IT:
			pronoun_forms = PackedStringArray(["it", "it", "its", "its", "itself"])
		_:
			pronoun_forms = PackedStringArray(["he", "him", "his", "his", "himself"])

	return pronoun_forms[pronoun_type - 1]

func va(speaker_id, singular_form : String, plural_form : String) -> String:
	var resolved_speaker : SpeakerResource = _resolve_inline_speaker_resource(speaker_id)
	if resolved_speaker == null:
		return singular_form

	if resolved_speaker.pronoun == SpeakerResource.GENDER.THEY:
		return plural_form

	return singular_form


func resolve_speaker_id(line_or_id) -> StringName:
	if line_or_id == null:
		return &""

	if line_or_id is DialogueLine:
		var raw_from_line : String = (line_or_id as DialogueLine).character.strip_edges()
		if raw_from_line.is_empty():
			return &""
		return StringName(raw_from_line)

	return _to_speaker_key(line_or_id)

func resolve_mood(line_or_tag_data) -> StringName:
	var raw : String = ""

	if line_or_tag_data == null:
		raw = ""
	elif line_or_tag_data is DialogueLine:
		var line : DialogueLine = line_or_tag_data as DialogueLine
		if line.has_tag("mood"):
			raw = line.get_tag_value("mood")
	elif line_or_tag_data is PackedStringArray:
		raw = _read_tag_value_from_tags(line_or_tag_data, "mood")
	elif line_or_tag_data is Array:
		raw = _read_tag_value_from_tags(PackedStringArray(line_or_tag_data), "mood")
	elif line_or_tag_data is Dictionary:
		var dict : Dictionary = line_or_tag_data
		if dict.has("mood"):
			raw = String(dict["mood"])
		elif dict.has("tags"):
			raw = _read_tag_value_from_tags(PackedStringArray(dict["tags"]), "mood")
	elif line_or_tag_data is String or line_or_tag_data is StringName:
		raw = String(line_or_tag_data)

	raw = raw.strip_edges().to_lower()
	if raw.is_empty():
		return &"normal"
	return StringName(raw)

func resolve_portrait_pair(speaker : SpeakerResource, mood : StringName) -> Dictionary:
	var result : Dictionary = {
		"close": null,
		"open": null,
	}

	if speaker == null:
		return result

	# Contract: normal_close is the baseline. If it is missing, portraits are treated as absent.
	if speaker.normal_close == null:
		return result

	var resolved_mood : StringName = mood
	if resolved_mood == &"":
		resolved_mood = &"normal"

	var close_tex : Texture2D = _get_close_portrait_for_mood(speaker, resolved_mood)
	var open_tex : Texture2D = _get_open_portrait_for_mood(speaker, resolved_mood)

	# Missing requested mood falls back to normal.
	if close_tex == null:
		close_tex = speaker.normal_close
	if open_tex == null:
		open_tex = speaker.normal_open

	result["close"] = close_tex
	result["open"] = open_tex
	return result

func resolve_portrait_for_options(pair : Dictionary) -> Texture2D:
	if pair == null:
		return null

	var close_tex : Texture2D = pair.get("close", null)
	var open_tex : Texture2D = pair.get("open", null)

	# Options.portrait_type
	# 0 TALKING: open when present
	# 1 STILL: close only
	if Options.portrait_type == 0:
		if open_tex != null:
			return open_tex
		return close_tex
	return close_tex

func resolve_voice_stream(speaker : SpeakerResource) -> AudioStream:
	if speaker == null:
		return default_voice
	if speaker.voice != null:
		return speaker.voice
	return default_voice

func resolve_voice_pitch_min(speaker : SpeakerResource) -> float:
	var pitch : Dictionary = _resolve_pitch_range(speaker)
	return pitch["min"]

func resolve_voice_pitch_max(speaker : SpeakerResource) -> float:
	var pitch : Dictionary = _resolve_pitch_range(speaker)
	return pitch["max"]

func set_active_context(speaker_id, mood) -> void:
	var author_key : StringName = _to_speaker_key(speaker_id)
	if author_key == &"":
		clear_active_context()
		return

	active_mood = resolve_mood(mood)

	var resolved_speaker : SpeakerResource = null
	var resolved_id : StringName = author_key

	if author_key == &"PLAYER":
		resolved_speaker = _resolve_controlled_party_speaker_resource()

		# Fallback when party context is missing or the member has no speaker_resource
		if resolved_speaker == null:
			resolved_speaker = find_speaker_by_id(author_key)

		if resolved_speaker != null and not resolved_speaker.speaker_id.is_empty():
			resolved_id = StringName(resolved_speaker.speaker_id)
	else:
		resolved_speaker = find_speaker_by_id(author_key)
		if resolved_speaker != null and not resolved_speaker.speaker_id.is_empty():
			resolved_id = StringName(resolved_speaker.speaker_id)

	active_speaker_id = resolved_id
	active_speaker = resolved_speaker

	active_display_name = _resolve_display_name(active_speaker_id, active_speaker)

	var pair : Dictionary = resolve_portrait_pair(active_speaker, active_mood)
	active_portrait_close = pair["close"]
	active_portrait_open = pair["open"]

	active_voice_stream = resolve_voice_stream(active_speaker)
	active_pitch_min = resolve_voice_pitch_min(active_speaker)
	active_pitch_max = resolve_voice_pitch_max(active_speaker)
	
	
func clear_active_context() -> void:
	active_speaker_id = &""
	active_mood = &"normal"
	active_speaker = null
	active_display_name = ""
	active_portrait_close = null
	active_portrait_open = null
	active_voice_stream = default_voice
	active_pitch_min = 1.0
	active_pitch_max = 1.0
	
func set_run_speakers(speakers : Array[SpeakerResource]) -> void:
	_run_speaker_by_id.clear()
	for s in speakers:
		if s == null:
			continue
		if s.speaker_id.is_empty():
			continue
		_run_speaker_by_id[StringName(s.speaker_id)] = s

func clear_run_speakers() -> void:
	_run_speaker_by_id.clear()
	
func set_active_balloon(balloon : Node) -> void:
	active_balloon = balloon
func clear_active_balloon(balloon : Node = null) -> void:
	var did_clear : bool = false

	# Always drop an invalid reference.
	if active_balloon != null and not is_instance_valid(active_balloon):
		active_balloon = null
		did_clear = true

	# Unbind only if the balloon matches the current active one.
	if balloon != null:
		if active_balloon == balloon:
			active_balloon = null
			did_clear = true

	if did_clear:
		_try_finalize_dialogue_session()


func close_active_balloon() -> void:
	force_cleanup_dialogue_session()


## Force close / invalidate the active balloon and finalize the current dialogue session.
## This path exists for scene changes and cutscene authored hard exits.
func force_cleanup_dialogue_session() -> void:
	var should_finalize : bool = false
	if has_active_balloon():
		should_finalize = true
	if _active_dialogue_resource != null:
		should_finalize = true
	if active_speaker_id != &"":
		should_finalize = true
	if _run_speaker_by_id.size() > 0:
		should_finalize = true

	if should_finalize:
		# Mark the session ended, even if DialogueManager.dialogue_ended will never fire.
		_dialogue_session_active = true
		_dialogue_end_received = true

	var balloon : Node = active_balloon
	if balloon != null and is_instance_valid(balloon):
		# Queue free is the safest option during transitions.
		balloon.queue_free()

	# Drop the reference immediately so callers can treat the balloon as invalidated.
	clear_active_balloon(balloon)
	_try_finalize_dialogue_session()


func has_active_balloon() -> bool:
	if active_balloon == null:
		return false
	if not is_instance_valid(active_balloon):
		active_balloon = null
		_try_finalize_dialogue_session()
		return false
	if active_balloon.is_queued_for_deletion():
		return false
	return true

#endregion

#region Convenience getters for the active context

func has_active_portrait() -> bool:
	return active_portrait_close != null

func get_active_display_name() -> String:
	return active_display_name

func get_active_portrait_close() -> Texture2D:
	return active_portrait_close

func get_active_portrait_open() -> Texture2D:
	return active_portrait_open

func get_active_voice_stream() -> AudioStream:
	return active_voice_stream

func get_active_voice_pitch_min() -> float:
	return active_pitch_min

func get_active_voice_pitch_max() -> float:
	return active_pitch_max

func pick_active_voice_pitch() -> float:
	if active_pitch_max <= active_pitch_min:
		return active_pitch_min
	return randf_range(active_pitch_min, active_pitch_max)

#endregion

#region Dialogue entry helper


func prepare_dialogue_run(speakers : Array[SpeakerResource]) -> void:
	clear_active_context()
	set_run_speakers(speakers)

#region Dialogue entry helper

func show_dialogue(dialogue_resource : Resource, title : String = "", extra_game_states : Array = []) -> Node:
	var resource : DialogueResource = dialogue_resource as DialogueResource
	if resource == null:
		push_error("DM: show_dialogue dialogue_resource is null or not a DialogueResource")
		return null
	return start_dialogue(resource, title, extra_game_states)

func start_dialogue(resource : DialogueResource, title : String = "", extra_game_states : Array = []) -> Node:
	if resource == null:
		push_error("DM: start_dialogue resource is null")
		return null

	# Project authoring contract: every dialogue uses DM.
	if not resource.using_states.has("DM"):
		push_warning("DM: dialogue resource missing 'using DM': " + resource.resource_path)

	clear_active_context()
	_active_dialogue_resource = resource
	_dialogue_session_active = true
	_dialogue_end_received = false
	var balloon : Node = DialogueManager.show_dialogue_balloon(resource, title, extra_game_states)
	set_active_balloon(balloon)
	return balloon


#endregion

#region DialogueManager signal handlers
func _on_dialogue_started(_resource : DialogueResource) -> void:
	_dialogue_session_active = true
	_dialogue_end_received = false
	_active_dialogue_resource = _resource
	clear_active_context()
	dialogue_session_started.emit(_resource)

func _on_got_dialogue(line : DialogueLine) -> void:
	if line == null:
		clear_active_context()
		return

	var speaker_id : StringName = resolve_speaker_id(line)
	var mood : StringName = resolve_mood(line)
	set_active_context(speaker_id, mood)


func _on_dialogue_ended(_resource : DialogueResource) -> void:
	_dialogue_end_received = true
	_active_dialogue_resource = _resource
	_try_finalize_dialogue_session()

func _try_finalize_dialogue_session() -> void:
	if not _dialogue_session_active:
		return
	if not _dialogue_end_received:
		return
	if has_active_balloon():
		return

	clear_active_context()
	clear_run_speakers()

	var ended_resource : Resource = _active_dialogue_resource
	_active_dialogue_resource = null
	_dialogue_session_active = false
	_dialogue_end_received = false
	dialogue_session_ended.emit(ended_resource)

#endregion

#region Internals

func _register_speaker(speaker : SpeakerResource) -> void:
	if speaker.speaker_id.is_empty():
		push_warning("DM: SpeakerResource missing speaker_id: " + speaker.resource_path)
		return

	var speaker_key : StringName = StringName(speaker.speaker_id)
	if _speaker_by_id.has(speaker_key):
		push_warning("DM: duplicate speaker_id '\"%s\"' overwritten by: %s" % [speaker.speaker_id, speaker.resource_path])

	all_speakers.append(speaker)
	_speaker_by_id[speaker_key] = speaker

func _to_speaker_key(id) -> StringName:
	if id == null:
		return &""

	if id is StringName:
		var name_id : StringName = id
		if name_id == &"":
			return &""
		return name_id

	var raw : String = String(id).strip_edges()
	if raw.is_empty():
		return &""
	return StringName(raw)

func _resolve_inline_speaker_resource(speaker_id) -> SpeakerResource:
	var author_key : StringName = _to_speaker_key(speaker_id)
	if author_key == &"":
		return null

	if author_key == &"PLAYER":
		var controlled_speaker : SpeakerResource = _resolve_controlled_party_speaker_resource()
		if controlled_speaker != null:
			return controlled_speaker

	return find_speaker_by_id(author_key)


func _resolve_display_name(speaker_id : StringName, speaker : SpeakerResource) -> String:
	if speaker != null and not speaker.display_name.is_empty():
		return speaker.display_name
	return String(speaker_id)

func _resolve_pitch_range(speaker : SpeakerResource) -> Dictionary:
	var result : Dictionary = { "min": 1.0, "max": 1.0 }
	if speaker == null:
		return result

	var pitch_min : float = speaker.pitch_min
	var pitch_max : float = speaker.pitch_max

	if pitch_min <= 0.0:
		return result
	if pitch_max <= 0.0:
		return result
	if pitch_max < pitch_min:
		return result

	result["min"] = pitch_min
	result["max"] = pitch_max
	return result

func _read_tag_value_from_tags(tags : PackedStringArray, tag_name : String) -> String:
	var wrapped : String = "%s=" % tag_name
	for t in tags:
		if String(t).begins_with(wrapped):
			return String(t).replace(wrapped, "").strip_edges()
	return ""

func _get_close_portrait_for_mood(speaker : SpeakerResource, mood : StringName) -> Texture2D:
	match mood:
		&"angry":
			return speaker.angry_close
		&"happy":
			return speaker.happy_close
		&"sad":
			return speaker.sad_close
		&"surprise":
			return speaker.surprise_close
		&"special":
			return speaker.special_close
		&"tired":
			return speaker.tired_close
		&"normal":
			return speaker.normal_close
		_:
			return speaker.normal_close

func _get_open_portrait_for_mood(speaker : SpeakerResource, mood : StringName) -> Texture2D:
	match mood:
		&"angry":
			return speaker.angry_open
		&"happy":
			return speaker.happy_open
		&"sad":
			return speaker.sad_open
		&"surprise":
			return speaker.surprise_open
		&"special":
			return speaker.special_open
		&"tired":
			return speaker.tired_open
		&"normal":
			return speaker.normal_open
		_:
			return speaker.normal_open
		
func _resolve_controlled_party_speaker_resource() -> SpeakerResource:
	var controlled_member : PartyMemberData = CharDataKeeper.get_controlled_member()
	if controlled_member == null:
		return null
	return controlled_member.speaker_resource
	
	
func _find_runtime_party_speaker_by_actor_id(actor_id : StringName) -> SpeakerResource:
	if actor_id == &"":
		return null

	for member in CharDataKeeper.party_members:
		if member == null:
			continue
		if member.actor_id != actor_id:
			continue
		if member.speaker_resource != null:
			return member.speaker_resource

	for member in CharDataKeeper.outside_members:
		if member == null:
			continue
		if member.actor_id != actor_id:
			continue
		if member.speaker_resource != null:
			return member.speaker_resource

	return null
#endregion
