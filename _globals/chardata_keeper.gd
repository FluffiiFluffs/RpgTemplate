##chardata_keeper.gd
##Global script CharDataKeeper
##Global Script for keeping track of each playable character's stats, equipment etc
extends Node2D


#preloads here so other scripts can access the scenes easier
const PLAYER_CHARACTER = preload("uid://bita6dnrj87wq")
const _NPC = preload("uid://56kk082o8ck1")
const ENEMY = preload("uid://dt3hw6ocf2cl7")


@export_category("Party Setup")
##All recruitable characters with base stats.
@export var all_party_members : Array[PartyMemberData] = []
##Size of the party
@export_range(1,4,1) var party_size : int = 4
##Party members. Index 0 is always controlled by the player.
@export var party_members : Array[PartyMemberData] = []

@export_category("Field Control")
##Reference to the controlled character node on the field
@export var controlled_character : PlayerCharacter
##Index for the controlled character
var controlled_index : int = 0 : set = set_controlled_index


func _ready() -> void:
	_clean_party_array()

	if party_members.is_empty():
		return

	if controlled_index < 0 or controlled_index >= party_members.size():
		controlled_index = 0


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
