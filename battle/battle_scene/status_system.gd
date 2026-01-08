class_name StatusSystem
extends Node
##status_system.gd
## Central handler for status effects, buffs, debuffs, and turn based conditions.
## Answers whether a battler can act, runs turn start and turn end hooks, and modifies action outcomes.
## Provides hooks for changing stats, hit chance, damage, healing, and for reacting to events like taking damage.
## Does not own UI and does not decide turn order.

var battle_scene : BattleScene = null
