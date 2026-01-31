##chardata_keeper.gd
##Global script CharDataKeeper
##Global Script for keeping track of each playable character's stats, equipment etc
extends Node2D



@export_category("Party Setup")
##All recruitable characters with base stats.
@export var all_party_members : Array[PartyMemberData] = []
##Size of the party
@export_range(1,4,1) var party_size : int = 4
##Party members in the party
@export var party_members : Array[PartyMemberData] = []
##Party members not in party, but are not default
@export var outside_members : Array[PartyMemberData]

@export_category("Field Control")
##Reference to the controlled character node on the field
@export var controlled_character : FieldPartyMember
##Index for the controlled character
var controlled_index : int = 0 : set = set_controlled_index

@export_category("PartyWide Data")
@export var money : int = 0 ##How much money the party has
@export var time_played : float = 0 ##How much time has elapsed during the playthrough

signal field_poison_tick(actor : ActorData, damage : int)
signal poison_field_tick(member : ActorData, damage : int)

@export_category("Field Poison Tick")
@export var poison_field_step_distance : float = 32.0
@export var poison_field_tick_enabled : bool = true

var _poison_last_pos : Vector2 = Vector2.ZERO
var _poison_has_last_pos : bool = false
var _poison_distance_accum : float = 0.0




func _ready() -> void:
	_clean_party_array()

	if party_members.is_empty():
		return

	if controlled_index < 0 or controlled_index >= party_members.size():
		controlled_index = 0

func _process(_delta : float) -> void:
	if not poison_field_tick_enabled:
		_reset_poison_step_tracking()
		return

	if GameState.gamestate != GameState.State.FIELD:
		_reset_poison_step_tracking()
		return

	if controlled_character == null:
		_reset_poison_step_tracking()
		return

	var p : Vector2 = controlled_character.global_position

	if not _poison_has_last_pos:
		_poison_last_pos = p
		_poison_has_last_pos = true
		return

	var moved : float = (p - _poison_last_pos).length()
	_poison_last_pos = p

	if moved <= 0.0:
		return

	_poison_distance_accum += moved

	if poison_field_step_distance <= 0.0:
		_poison_distance_accum = 0.0
		return

	var steps : int = int(floor(_poison_distance_accum / poison_field_step_distance))
	if steps <= 0:
		return

	_poison_distance_accum = _poison_distance_accum - (float(steps) * poison_field_step_distance)

	for i in range(steps):
		_apply_poison_field_step()




## Remove null entries and clamp to party_size.
func _clean_party_array() -> void:
	var cleaned : Array[PartyMemberData] = []
	for member in party_members:
		if member != null:
			cleaned.append(member)

	party_members = cleaned

	if party_members.size() > party_size:
		party_members.resize(party_size)


func set_controlled_index(value : int) -> void:
	controlled_index = value

	if party_members.is_empty():
		controlled_index = 0
		return

	if controlled_index < 0:
		controlled_index = 0

	if controlled_index >= party_members.size():
		controlled_index = party_members.size() - 1


func get_controlled_member() -> PartyMemberData:
	if party_members.is_empty():
		return null

	if controlled_index < 0 or controlled_index >= party_members.size():
		return null

	return party_members[controlled_index]


func get_member(slot_index : int) -> PartyMemberData:
	if slot_index < 0:
		return null

	if slot_index >= party_members.size():
		return null

	return party_members[slot_index]


func add_party_member(member : PartyMemberData) -> void:
	if member == null:
		return

	if party_members.has(member):
		return

	if party_members.size() >= party_size:
		return

	party_members.append(member)


func remove_party_member(member : PartyMemberData) -> void:
	if member == null:
		return

	var index := party_members.find(member)
	if index == -1:
		return

	party_members.remove_at(index)

	if party_members.is_empty():
		controlled_index = 0
		return

	if controlled_index >= party_members.size():
		controlled_index = party_members.size() - 1


func create_member_from_char(char_res : CharResource, new_id : StringName = "") -> PartyMemberData:
	if char_res == null:
		return null

	var member := PartyMemberData.new()
	member.init_from_char_resource(char_res, new_id)
	return member


func create_and_add_member_from_char(char_res : CharResource, new_id : StringName = "") -> PartyMemberData:
	var member := create_member_from_char(char_res, new_id)
	if member == null:
		return null

	add_party_member(member)
	return member



func _reset_poison_step_tracking() -> void:
	_poison_distance_accum = 0.0
	_poison_has_last_pos = false


func _apply_poison_field_step() -> void:
	if party_members == null:
		return

	for member in party_members:
		if member == null:
			continue

		if member.current_hp <= 0:
			_remove_death_cleared_statuses_field(member)
			continue

		var poison : StatusEffectPoison = null
		for s in member.status_effects:
			if s == null:
				continue
			if s is StatusEffectPoison:
				poison = s
				break

		if poison == null:
			continue

		var dmg : int = poison.get_field_dot_damage(member)
		if dmg <= 0:
			continue

		member.current_hp = clampi(member.current_hp - dmg, 0, member.get_max_hp())
		field_poison_tick.emit(member, dmg)
		
		if member.current_hp <= 0:
			_remove_death_cleared_statuses_field(member)


func _remove_death_cleared_statuses_field(actor : ActorData) -> void:
	if actor == null:
		return
	if actor.status_effects == null:
		return

	for i in range(actor.status_effects.size() - 1, -1, -1):
		var s : StatusEffect = actor.status_effects[i]
		if s == null:
			actor.status_effects.remove_at(i)
			continue

		if s.remove_on_death:
			s.on_remove(null)
			actor.status_effects.remove_at(i)
