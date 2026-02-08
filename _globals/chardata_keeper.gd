##chardata_keeper.gd
##Global script CharDataKeeper
##Global Script for keeping track of each playable character's stats, equipment etc
extends Node2D

#Timer exists to add to poison_threshold
@onready var poison_timer: Timer = %PoisonTimer


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
@export var field_party_nodes : Array[FieldPartyMember] = []
@export var party_is_moving : bool = false
@export var player_trying_move : bool = false

@export_category("PartyWide Data")
@export var money : int = 0 ##How much money the party has
@export var time_played : float = 0 ##How much time has elapsed during the playthrough
##File that keeps the list of HP and SP mod values per level (shared between all characters)
@export var hp_sp_mod : HPSPMod = null


signal field_poison_tick(actor : ActorData, damage : int)

@export_category("Field Poison Tick")
##Amount needed to tick poison
@export var poison_threshold : float = 50
##Added to when player is moving, is controlled, and any party member has poison
@export var poison_accumulated : float = 0
##Amount to add to poison accumulated each time poison_timer times out
@export var poison_acc_amount : float = 1.0
@export var poison_acc_amount_run : float = 2.0

var _poison_last_pos : Vector2 = Vector2.ZERO
var field_status_system : StatusSystem = StatusSystem.new()



func _ready() -> void:
	_clean_party_array()

	if party_members.is_empty():
		return

	if controlled_index < 0 or controlled_index >= party_members.size():
		controlled_index = 0
	poison_timer.timeout.connect(poison_timer_timeout)


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
	poison_accumulated = 0.0

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

		var raw_dmg : int = poison.get_field_dot_damage(member)
		if raw_dmg <= 0:
			continue

		# Cap damage so HP never drops below 1.
		var max_allowed : int = member.current_hp - 1
		if max_allowed < 0:
			max_allowed = 0

		var applied_dmg : int = raw_dmg
		if applied_dmg > max_allowed:
			applied_dmg = max_allowed

		# Only apply damage when it is positive.
		if applied_dmg > 0:
			member.current_hp = clampi(member.current_hp - applied_dmg, 1, member.get_max_hp())

		# Always emit so field visuals still fire at 1 HP.
		field_poison_tick.emit(member, applied_dmg)



func _remove_death_cleared_statuses_field(actor : ActorData) -> void:
	if actor == null:
		return
	if actor.status_effects == null:
		return
	if field_status_system == null:
		return

	var dummy : Battler = Battler.new()
	dummy.actor_data = actor
	field_status_system.on_death(dummy)

			
##Determines if any party members have poison. If they do, then poison flash is enabled on their field sprite. Movement of a certain distance causes the poison to add to a threshold. When the threshold is met, poison tics on the affected party member.
func poison_timer_timeout()->void:
	if not is_instance_valid(controlled_character):
		controlled_character = null
		#_reset_poison_step_tracking()
		return


	var poison_active : bool = false

	# Always refresh poison flash state first.
	for m in party_members:
		var member_has_poison : bool = false

		for e in m.status_effects:
			if e is StatusEffectPoison:
				member_has_poison = true
				break

		if member_has_poison:
			poison_active = true

		var fscene : FieldPartyMember = get_runtime_party_field_scene(m)
		if fscene == null:
			continue
		fscene.set_poison_flash(member_has_poison)

	# Menu should not run movement accumulation or field DOT.
	if GameState.gamestate == GameState.State.GAMEMENU:
		return


	if poison_active == false:
		_reset_poison_step_tracking()
		return


	if _poison_last_pos.distance_to(controlled_character.global_position) <= 0.01:
		return

	_poison_last_pos = controlled_character.global_position

	if poison_accumulated >= poison_threshold:
		poison_accumulated = 0.0
		_apply_poison_field_step()
		poison_timer.start()
	else:
		if controlled_character.is_running:
			poison_accumulated += poison_acc_amount_run
		else:
			poison_accumulated += poison_acc_amount
		poison_timer.start()




func get_runtime_party_field_scene(_pmdata : PartyMemberData)->FieldPartyMember:
	if !field_party_nodes.is_empty(): ##if there's party members, which there should be
		for node in field_party_nodes: #loop through the array
			if node.pm_id == _pmdata.pm_id:
				return node
	return null #if for some reason it's empty, return null. This should never happen.
