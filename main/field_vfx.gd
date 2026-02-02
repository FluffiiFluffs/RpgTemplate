class_name FieldVFX
extends Node2D

const POISONBUBBLE = preload("uid://csucisuhwvqev")

func _ready()->void:
	CharDataKeeper.field_poison_tick.connect(make_poison_bubble)
	

##Instantiates a poison bubble above the actor
func make_poison_bubble(actor : ActorData, _damage : int)->void:
	var pmdata = actor as PartyMemberData
	var fscene = CharDataKeeper.get_runtime_party_field_scene(pmdata)
	var new_poison_bubble : PoisonBubble = POISONBUBBLE.instantiate()
	add_child(new_poison_bubble)
	new_poison_bubble.global_position = fscene.poison_marker_2d.global_position
	
	pass
##
