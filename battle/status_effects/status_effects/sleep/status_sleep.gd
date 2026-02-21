class_name StatusEffectSleep
extends StatusEffect
#[Sleep]
	#Target unable to act during their turn if sleep is active
	#Target is kept in turn queue
	#Target unable to select commands
	#During target's turn, there is a 1/4 chance they will wake up (random roll)
		#If wake up roll is successful, commands are able to selected (meaning, this calculation needs to happen before anything else as with other status effects)
		#Target also regenerates 5% of their health per turn if they fail the wakeup roll
	#Being stunned or confused overwrites this effect
	#Damage to the target has 1/2 a chance to wake them
	#All attacks against the target always land
	#Can be healed with items/skills that "heal all"
		#so an effect_healsleep needs to be made eventually
	#Is not broken by poison (user still takes damage during sleep)
		#So sleep+poison is a great combo
	#Does not persist after battle
	#Does not persist after death

@export_range(0.0, 1.0, 0.01) var wake_chance_turn_start : float = 0.25
@export_range(0.0, 1.0, 0.01) var wake_chance_on_damage : float = 0.5
@export_range(0.0, 1.0, 0.01) var regen_max_hp_percent_on_fail : float = 0.05

func blocks_turn(_status_system : StatusSystem, _battler : Battler) -> bool:
	return true

func blocks_command_selection(_status_system : StatusSystem, _battler : Battler) -> bool:
	return true

func on_turn_start_tick(status_system : StatusSystem) -> bool:
	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return false
	if actor.current_hp <= 0:
		return false

	var bs : BattleScene = null
	if status_system != null:
		bs = status_system.battle_scene

	var name_text : String = actor.get_display_name()
	if name_text == "":
		name_text = "Someone"

	# Wake check before command selection
	if randf() < wake_chance_turn_start:
		if status_system != null:
			var battler : Battler = status_system.get_battler_for_actor(actor)
			if battler != null:
				status_system.remove_status(battler, self)

		if bs != null and bs.battle_notify_ui != null:
			bs.battle_notify_ui.queue_notification(name_text + " wakes up!")
		return true

	# Still asleep, regen
	var max_hp : int = actor.get_max_hp()
	var raw : float = float(max_hp) * regen_max_hp_percent_on_fail
	var heal : int = int(ceil(raw))
	if heal < 1:
		heal = 1

	var before_hp : int = actor.current_hp
	actor.current_hp = clampi(actor.current_hp + heal, 0, max_hp)
	var applied_heal : int = actor.current_hp - before_hp

	if bs != null and bs.battle_notify_ui != null:
		var actions : Array[Callable] = []
		if applied_heal > 0 and status_system != null and bs != null and bs.battle_vfx != null:
			var battler2 : Battler = status_system.get_battler_for_actor(actor)
			if battler2 != null:
				actions.append(Callable(bs.battle_vfx, "pop_text_healing").bind(battler2, applied_heal))
		bs.battle_notify_ui.queue_notification(name_text + " snores loudly.", actions)

	return true


static func try_wake_on_damage(status_system : StatusSystem, target_battler : Battler, ctx : EffectContext = null) -> bool:
	if status_system == null:
		return false
	if target_battler == null:
		return false

	var s : StatusEffect = StatusSystem.find_status(target_battler, StatusEffectSleep)
	if s == null:
		return false

	var sleep : StatusEffectSleep = s as StatusEffectSleep
	if sleep == null:
		return false

	if randf() >= sleep.wake_chance_on_damage:
		return false

	status_system.remove_status(target_battler, sleep)

	var name_text : String = "Someone"
	if target_battler.actor_data != null:
		name_text = target_battler.actor_data.get_display_name()

	if ctx != null:
		ctx.queue_battle_message(name_text + " wakes up!", target_battler)
	else:
		if status_system.battle_scene != null and status_system.battle_scene.battle_notify_ui != null:
			status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " wakes up!")

	return true


func on_receive_damage(status_system : StatusSystem, defender : Battler, _attacker : Battler, _action_use : ActionUse, dmg_ctx : Dictionary) -> void:
	if status_system == null:
		return
	if defender == null:
		return
	if defender.actor_data == null:
		return

	var actor : ActorData = get_receiver_actor()
	if actor == null:
		return
	if defender.actor_data != actor:
		return

	if dmg_ctx != null:
		if dmg_ctx.has("is_dot") and bool(dmg_ctx["is_dot"]):
			return
		if dmg_ctx.has("is_poison") and bool(dmg_ctx["is_poison"]):
			return
		if dmg_ctx.has("amount") and int(dmg_ctx["amount"]) <= 0:
			return

	if randf() >= wake_chance_on_damage:
		return

	status_system.remove_status(defender, self)

	var name_text : String = "Someone"
	if defender.actor_data != null:
		name_text = defender.actor_data.get_display_name()

	var ctx : EffectContext = null
	if dmg_ctx != null and dmg_ctx.has("effect_context"):
		ctx = dmg_ctx["effect_context"] as EffectContext

	if ctx != null:
		ctx.queue_battle_message(name_text + " wakes up!", defender)
	elif status_system.battle_scene != null and status_system.battle_scene.battle_notify_ui != null:
		status_system.battle_scene.battle_notify_ui.queue_notification(name_text + " wakes up!")



func forces_physical_hit(_status_system : StatusSystem, battler : Battler) -> bool:
	if battler == null:
		return false
	if battler.actor_data == null:
		return false
	if battler.actor_data != get_receiver_actor():
		return false
	return true
