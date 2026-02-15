class_name EffectContext
extends RefCounted
## Runtime context object passed into Effect.can_apply() and Effect.apply().
##
## Purpose
## This object carries execution mode plus optional battle references so Effect code can run in:
##   1) Field usage, for inventory and menu actions
##   2) Battle usage, for skill and item execution and for targeting previews
##
## Common usage patterns
##   Targeting and previews:
##     CommandController builds a BATTLE context via make_battle_targeting().
##     Effects read ctx.current_target_battler (set by Effect.can_apply_to_battler()) to validate targets.
##
##   Execution:
##     ActionResolver builds a BATTLE context via make_battle_execution().
##     Effects can rely on BattleScene and StatusSystem references after calling require_battle_context().
##
## Message and feedback channel
##   Effects can queue battle message templates through queue_battle_message().
##   ActionResolver flushes these messages after effect execution and uses had_effect_feedback
##   to decide whether to show generic fallback messaging such as "It has no effect."


enum Mode { FIELD, BATTLE }

## Execution mode used by Effect.scope gating and by Effect code that requires battle only services.
var mode : int = Mode.FIELD

## ActorData for the entity that initiated the action.
## In battle, this is typically current_user_battler.actor_data.
var user_actor : ActorData = null

## BattleScene reference for battle mode execution.
## Effects use this to reach VFX, UI, text parsing, and other battle services.
var battle_scene : BattleScene = null

## StatusSystem reference for battle mode execution.
## Effects use this for intercept, defend, damage hooks, and status driven modifiers.
var status_system : StatusSystem = null

## Battler currently being evaluated or modified by an Effect call.
## This is set by Effect.can_apply_to_battler() and Effect.apply_to_battler() wrappers.
var current_target_battler : Battler = null

## Optional source item for item execution and item based target filtering.
## CommandController and ActionResolver set this when evaluating or executing item effects.
var source_item : Item = null

## Message templates produced by effects during battle execution.
## ActionResolver reads and flushes these into BattleNotifyUI after effect application.
var queued_battle_messages : Array[String] = []

## Optional per message target override used for parsing message templates.
## When present, ActionResolver uses this battler as the parse target for that queued message.
var queued_battle_message_targets : Array[Battler] = []

## Battler node for the action user during battle execution.
## Set by make_battle_targeting() and used by effects that need a Battler reference for the user.
var current_user_battler : Battler = null

## ActionUse being executed.
## Set only for execution contexts created via make_battle_execution().
var current_action_use : ActionUse = null

## Legacy damage popup bookkeeping.
## Current implementation tracks this on ActionUse.data under the key "popped_user_damage".
## This field remains for compatibility with older effect code and can be removed after cleanup.
var popped_user_damage : int = 0

## Feedback flag used by ActionResolver to determine whether generic "no effect" messaging is needed.
## Effects that show messages, spawn VFX, or otherwise provide visible output should set this true.
var had_effect_feedback : bool = false



## Creates a battle context intended for targeting and preview checks.
## This context includes BattleScene and StatusSystem references, plus current_user_battler and user_actor.
## current_action_use remains null because target filtering happens before an ActionUse exists.
static func make_battle_targeting(user : Battler, battle_scene : BattleScene) -> EffectContext:
	assert(user != null)
	assert(user.actor_data != null)
	assert(battle_scene != null)
	assert(battle_scene.status_system != null)

	var ctx : EffectContext = EffectContext.new()
	ctx.mode = Mode.BATTLE
	ctx.user_actor = user.actor_data
	ctx.battle_scene = battle_scene
	ctx.status_system = battle_scene.status_system
	ctx.current_user_battler = user
	return ctx


## Creates a battle context intended for skill and item execution.
## Sets current_action_use and then asserts that all required battle references are present.
static func make_battle_execution(use : ActionUse, battle_scene : BattleScene) -> EffectContext:
	assert(use != null)
	assert(use.user != null)

	var ctx : EffectContext = make_battle_targeting(use.user, battle_scene)
	ctx.current_action_use = use
	ctx.require_battle_context()
	return ctx


## Asserts that this EffectContext is fully configured for battle execution.
## Effects call this at the start of apply() when they require battle services and attribution data.
func require_battle_context() -> void:
	assert(mode == Mode.BATTLE)
	assert(user_actor != null)
	assert(battle_scene != null)
	assert(status_system != null)
	assert(current_user_battler != null)
	assert(current_action_use != null)


## Queues a battle message template produced by an Effect.
## target_battler optionally supplies a parsing target override for this specific message.
func queue_battle_message(text : String, target_battler : Battler = null) -> void:
	if text == "":
		return

	had_effect_feedback = true
	queued_battle_messages.append(text)
	queued_battle_message_targets.append(target_battler)
