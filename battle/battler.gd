class_name Battler
extends Node

enum Faction {PARTY, ENEMY}

@export var actor_data : ActorData = null
@export var faction : Faction = Faction.PARTY
