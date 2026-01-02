class_name Battler
extends Node
##battler.gd
##Attached to instantiated battler node within the battle_scene.tscn under Battlers node


enum Faction {PARTY, ENEMY}

##Actor data for the battler
@export var actor_data : ActorData = null
##Which side the battler is on
@export var faction : Faction = Faction.PARTY
##Reference to the battler's scene
@export var battler_scene : PackedScene = null
@export var battler_icon = null
@export var tie_roll : int = 0
