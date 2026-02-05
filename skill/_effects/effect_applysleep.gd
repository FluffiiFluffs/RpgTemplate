class_name EffectApplySleep
extends Effect
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
func _init() -> void:
	scope = Scope.BATTLE_ONLY


func can_apply(ctx : EffectContext, target : ActorData) -> bool:
	if not super.can_apply(ctx, target):
		return false
	if target.current_hp <= 0:
		return false
	if ctx.mode != EffectContext.Mode.BATTLE:
		return false
	if ctx.status_system == null:
		return false
	if ctx.current_target_battler == null:
		return false
	return true

func apply(ctx : EffectContext, target : ActorData) -> bool:
	if not can_apply(ctx, target):
		return false

	var new_sleep : StatusEffectSleep = StatusEffectSleep.new()

	var caster_battler : Battler = null
	if ctx.battle_scene != null:
		caster_battler = ctx.battle_scene.acting_battler

	var result : Dictionary = ctx.status_system.try_add_status(ctx.current_target_battler, new_sleep, caster_battler)

	if result.has("outcome"):
		if result["outcome"] == StatusSystem.AddStatusOutcome.BLOCKED:
			if result.has("blocked_by") and result["blocked_by"] is StatusEffectSleep:
				ctx.queue_battle_message("{target} is already asleep.", ctx.current_target_battler)
			else:
				ctx.queue_battle_message("{target} cannot fall asleep.", ctx.current_target_battler)
			return false

	# Target is put to sleep (APPLIED or REPLACED)
	ctx.queue_battle_message("{target} falls into a deep sleep...", ctx.current_target_battler)
	return true
