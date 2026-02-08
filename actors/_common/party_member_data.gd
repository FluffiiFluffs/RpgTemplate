class_name PartyMemberData
extends ActorData
##Resource used to hold party member data in the running game

@export_category("Identity")
##CharResource file used as a base for this party member.
@export var stats_sprite : Texture2D
@export var class_color : Color = Color()

@export_category("Stats")
@export var stats_table : StatsTable = null
