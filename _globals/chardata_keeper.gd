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
@export var exp_table : ExpTable = null

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
	_rebuild_party_member_base_stats()
	_refresh_all_next_level_exp()
	if party_members.is_empty():
		return

	if controlled_index < 0 or controlled_index >= party_members.size():
		controlled_index = 0
	poison_timer.timeout.connect(poison_timer_timeout)


func _rebuild_party_member_base_stats() -> void:
	_rebuild_member_array_base_stats(party_members)
	_rebuild_member_array_base_stats(outside_members)
	_rebuild_member_array_base_stats(all_party_members)


func _rebuild_member_array_base_stats(members : Array[PartyMemberData]) -> void:
	if members == null:
		return
	for member in members:
		if member == null:
			continue
		member.rebuild_base_stats()


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
			if node.actor_id == _pmdata.actor_id:
				return node
	return null #if for some reason it's empty, return null. This should never happen.




#region LEVELING

## Refresh next_level_exp for every member that exists in party_members.
## next_level_exp is stored threshold EXP needed from the current level to the next.
func _refresh_all_next_level_exp() -> void:
	if party_members == null:
		return
	for member in party_members:
		refresh_next_level_exp_for_member(member)


## Updates a single party member's stored threshold (next_level_exp) using ExpTable.
## Array index 0 corresponds to level 1 to level 2.
func refresh_next_level_exp_for_member(member : PartyMemberData) -> void:
	if member == null:
		return

	var level_cap : int = _get_exp_level_cap()

	# Max level behavior: keep gaining EXP totals, never allow another level.
	if member.level >= level_cap:
		if member.level > level_cap:
			member.level = level_cap
		member.next_level_exp = 0
		return

	member.next_level_exp = get_next_level_threshold_for_level(member.level, 0)

## Returns the EXP threshold for the given current level.
## For example level 1 reads exp_to_next_level[0].
## When no further level exists, returns 0.
func get_next_level_threshold_for_level(level_value : int, fallback : int = 0) -> int:
	if exp_table == null:
		return fallback
	if exp_table.exp_table == null:
		return fallback
	if exp_table.exp_table.is_empty():
		return 0

	var level_cap : int = _get_exp_level_cap()
	if level_value >= level_cap:
		return 0

	var index : int = level_value - 1
	if index < 0:
		index = 0
	if index >= exp_table.exp_table.size():
		return 0

	return int(exp_table.exp_table[index])



## Processes level ups for all party members based on current_exp and next_level_exp.
## Returns structured results for members that gained at least one level.
func process_party_level_ups(queue_battle_messages : bool = true) -> Array[Dictionary]:
	var out : Array[Dictionary] = []
	if party_members == null:
		return out

	for member in party_members:
		if member == null:
			continue
		if member.current_hp <= 0:
			continue

		var res : Dictionary = _process_member_level_ups(member, queue_battle_messages)
		if not res.is_empty():
			out.append(res)

	return out


## Safe multi level loop with guards: level cap, required exp > 0, safety counter
func _process_member_level_ups(member : PartyMemberData, queue_battle_messages : bool) -> Dictionary:
	if member == null:
		return {}

	refresh_next_level_exp_for_member(member)

	var start_level : int = member.level
	var start_stats : Dictionary = _capture_progression_stats(member)

	var gained_levels : int = 0
	var safety_counter : int = 0
	var safety_limit : int = 99
	var level_cap : int = _get_exp_level_cap()

	while member.current_exp >= member.next_level_exp and member.next_level_exp > 0 and member.level < level_cap:
		safety_counter = safety_counter + 1
		if safety_counter > safety_limit:
			printerr("Level up loop guard tripped for member: ", member.get_display_name())
			break

		var before_stats : Dictionary = _capture_progression_stats(member)

		var old_current_hp : int = member.current_hp
		var old_current_sp : int = member.current_sp

		var old_level : int = member.level

		## subtract threshold as carryover
		member.current_exp = member.current_exp - member.next_level_exp

		## increment level
		member.level = member.level + 1

		## rebuild base stats (PartyMemberData policy)
		member.rebuild_base_stats()

		## recompute next threshold
		refresh_next_level_exp_for_member(member)

		## current HP/SP behavior: add increase in max to current, then clamp
		var old_max_hp : int = int(before_stats.get("max_hp", 0))
		var old_max_sp : int = int(before_stats.get("max_sp", 0))
		var new_max_hp : int = member.get_max_hp()
		var new_max_sp : int = member.get_max_sp()

		var delta_max_hp : int = new_max_hp - old_max_hp
		var delta_max_sp : int = new_max_sp - old_max_sp

		member.current_hp = old_current_hp + delta_max_hp
		member.current_sp = old_current_sp + delta_max_sp
		member.clamp_vitals()

		gained_levels = gained_levels + 1

		if queue_battle_messages:
			_queue_battle_level_up_messages(member, before_stats, delta_max_hp, delta_max_sp)

	if gained_levels <= 0:
		return {}

	var end_level : int = member.level
	var end_stats : Dictionary = _capture_progression_stats(member)

	## deltas based on raw stat totals: Max HP, Max SP, STR, STM, AGI, MAG, LCK
	var deltas : Dictionary = {
		"max_hp": int(end_stats.get("max_hp", 0)) - int(start_stats.get("max_hp", 0)),
		"max_sp": int(end_stats.get("max_sp", 0)) - int(start_stats.get("max_sp", 0)),
		"strength": int(end_stats.get("strength", 0)) - int(start_stats.get("strength", 0)),
		"stamina": int(end_stats.get("stamina", 0)) - int(start_stats.get("stamina", 0)),
		"agility": int(end_stats.get("agility", 0)) - int(start_stats.get("agility", 0)),
		"magic": int(end_stats.get("magic", 0)) - int(start_stats.get("magic", 0)),
		"luck": int(end_stats.get("luck", 0)) - int(start_stats.get("luck", 0)),
	}

	return {
		"member": member,
		"old_level": start_level,
		"new_level": end_level,
		"levels_gained": gained_levels,
		"deltas": deltas,
		"start_stats": start_stats,
		"end_stats": end_stats,
	}


func _get_exp_level_cap() -> int:
	if exp_table == null:
		return 99
	if exp_table.exp_table == null:
		return 99
	if exp_table.exp_table.is_empty():
		return 1

	# Project policy: ExpTable length defines the maximum level.
	return exp_table.exp_table.size()

func get_max_level() -> int:
	return _get_exp_level_cap()



func _capture_progression_stats(member : PartyMemberData) -> Dictionary:
	if member == null:
		return {}
	return {
		"max_hp": member.get_max_hp(),
		"max_sp": member.get_max_sp(),
		"strength": member.get_strength(),
		"stamina": member.get_stamina(),
		"agility": member.get_agility(),
		"magic": member.get_magic(),
		"luck": member.get_luck(),
	}
	

func _queue_battle_level_up_messages(member : PartyMemberData, before_stats : Dictionary, delta_max_hp : int, delta_max_sp : int) -> void:
	# Bundled, single-notification level-up message for battle.
	# Output format:
	#   Line 1: "<Name> reached Level <N>."
	#   Line 2: "<Stat A> +X  <Stat B> +Y  ..."
	#
	# This is intentionally one queued message per level gained so that:
	#   1) When multiple party members level in one battle, each member's gains are clearly grouped.
	#   2) When one member gains multiple levels at once, each level's gains are shown as a discrete 2-line block.

	# Defensive guard: if the member reference is invalid, do nothing.
	if member == null:
		return

	# Compute deltas for core stats by comparing the member's CURRENT values against the snapshot taken
	# immediately before applying the level-up (before_stats).
	#
	# before_stats is expected to contain integer values under these keys:
	#   "strength", "stamina", "agility", "magic", "luck"
	#
	# Using int(before_stats.get(key, 0)) makes the function resilient if a key is missing.
	var delta_strength : int = member.get_strength() - int(before_stats.get("strength", 0))
	var delta_stamina : int = member.get_stamina() - int(before_stats.get("stamina", 0))
	var delta_agility : int = member.get_agility() - int(before_stats.get("agility", 0))
	var delta_magic : int = member.get_magic() - int(before_stats.get("magic", 0))
	var delta_luck : int = member.get_luck() - int(before_stats.get("luck", 0))

	# Build a list of formatted gain tokens for the second line.
	# _append_level_up_gain_part() is expected to add something like "STR +1" only when the delta > 0
	# (or whatever rule you have chosen there), which keeps the message compact.
	var parts : Array[String] = []
	_append_level_up_gain_part(parts, "Max HP", delta_max_hp)
	_append_level_up_gain_part(parts, "Max SP", delta_max_sp)
	_append_level_up_gain_part(parts, "STR", delta_strength)
	_append_level_up_gain_part(parts, "STM", delta_stamina)
	_append_level_up_gain_part(parts, "AGI", delta_agility)
	_append_level_up_gain_part(parts, "MAG", delta_magic)
	_append_level_up_gain_part(parts, "LCK", delta_luck)

	# First line (headline): explicitly states who leveled and what level they reached.
	# member.level is assumed to already be updated prior to calling this function.
	var headline : String = member.get_display_name() + " reached Level " + str(member.level) + "."

	# If there were no positive deltas (or _append_level_up_gain_part filtered everything out),
	# fall back to a simple one-line message.
	if parts.is_empty():
		_queue_battle_notification(headline)
		return

	# Join the gain tokens into a single line using double spaces for readability.
	# Example result: "Max HP +12  STR +1  AGI +1"
	var gains_line : String = ""
	for i in range(parts.size()):
		if i > 0:
			gains_line = gains_line + "  "
		gains_line = gains_line + parts[i]

	# Queue a single notification containing both lines, separated by "\n".
	# The battle notification UI should render this as a two-line block.
	_queue_battle_notification(headline + "\n" + gains_line)



func _append_level_up_gain_part(parts : Array[String], label : String, delta_value : int) -> void:
	if delta_value <= 0:
		return
	parts.append(label + " +" + str(delta_value))


func _format_delta(delta_value : int) -> String:
	if delta_value > 0:
		return "+" + str(delta_value)
	if delta_value < 0:
		return "minus " + str(abs(delta_value))
	return ""


## Allowed to call battle_scene systems from here for now.
func _queue_battle_notification(message : String) -> void:
	var main = null
	if SceneManager != null:
		main = SceneManager.main_scene
	if main == null:
		return
	if main.current_battle_scene == null:
		return
	if main.current_battle_scene.battle_notify_ui == null:
		return
	main.current_battle_scene.battle_notify_ui.queue_notification(message)

#endregion LEVELING
