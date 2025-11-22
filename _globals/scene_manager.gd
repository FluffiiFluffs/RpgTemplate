extends Node2D

const _NPC = preload("uid://56kk082o8ck1")
const PLAYER_CHARACTER = preload("uid://bita6dnrj87wq")
const _00_CHAR = preload("uid://prpth3t5akim")


##If the player is spawned
var player_is_made : bool = false
##If the party has been made or not
var party_is_made:bool=false
 ##needs to be used to store a location to spawn the party at when scene changes
var party_spawn_point

func make_player()->void:
	if player_is_made == false:
		CharDataKeeper.slot00 = _00_CHAR
		var new_player : PlayerCharacter = PLAYER_CHARACTER.instantiate()
		new_player.global_position = Vector2.ZERO ##TODO CHANGE THIS LATER!
		CharDataKeeper.controlled_character = new_player
		get_tree().current_scene.call_deferred("add_child", new_player)
		await get_tree().process_frame
		new_player.sprite_2d.texture = CharDataKeeper.slot00.char_sprite_sheet
		new_player.name = CharDataKeeper.slot00.char_name
		player_is_made = true

func make_party()->void:
	if CharDataKeeper.party_size == 1:
		return
	if party_is_made == false:
		var player = CharDataKeeper.controlled_character
		await get_tree().process_frame
		var scene_tree = player.get_parent()
		if CharDataKeeper.party_size > 1:
			if CharDataKeeper.party_size == 2:
				var party_member2 : NPC = _NPC.instantiate()
				party_member2.npc_data = CharDataKeeper.slot01
				party_member2.is_following = true
				party_member2.collisions_on = false
				party_member2.global_position = player.global_position + Vector2(0,-1)
				CharDataKeeper.party_member_02 = party_member2
				scene_tree.add_child.call_deferred(party_member2)
				await get_tree().process_frame
				party_member2.actor_to_follow = player
				party_member2.p_det_timer.timeout.disconnect(party_member2._check_for_player) 
				party_member2.name = str(CharDataKeeper.slot01.char_name)
				party_member2.p_det_timer.call_deferred("queue_free")
				party_member2.p_det_area.call_deferred("queue_free")
				pass
			elif CharDataKeeper.party_size == 3:
				var party_member2 : NPC = _NPC.instantiate()
				party_member2.npc_data = CharDataKeeper.slot01
				party_member2.is_following = true
				party_member2.collisions_on = false
				party_member2.global_position = player.global_position + Vector2(0,-1)
				CharDataKeeper.party_member_02 = party_member2
				scene_tree.add_child.call_deferred(party_member2)
				await get_tree().process_frame
				party_member2.actor_to_follow = player
				party_member2.p_det_timer.timeout.disconnect(party_member2._check_for_player) 
				party_member2.name = str(CharDataKeeper.slot01.char_name)
				party_member2.p_det_timer.call_deferred("queue_free")
				party_member2.p_det_area.call_deferred("queue_free")
				

				var party_member3 : NPC = _NPC.instantiate()
				party_member3.npc_data = CharDataKeeper.slot02
				party_member3.is_following = true
				party_member3.collisions_on = false
				party_member3.global_position = player.global_position + Vector2(0,-1)
				CharDataKeeper.party_member_03 = party_member3
				scene_tree.add_child.call_deferred(party_member3)
				await get_tree().process_frame
				party_member3.actor_to_follow = CharDataKeeper.party_member_02
				party_member3.p_det_timer.timeout.disconnect(party_member3._check_for_player) 
				party_member3.name = str(CharDataKeeper.slot02.char_name)
				party_member3.p_det_timer.call_deferred("queue_free")
				party_member3.p_det_area.call_deferred("queue_free")



			elif CharDataKeeper.party_size > 3:
				var party_member2 : NPC = _NPC.instantiate()
				party_member2.npc_data = CharDataKeeper.slot01
				party_member2.is_following = true
				party_member2.collisions_on = false
				party_member2.global_position = player.global_position + Vector2(0,-1)
				CharDataKeeper.party_member_02 = party_member2
				scene_tree.add_child.call_deferred(party_member2)
				await get_tree().process_frame
				party_member2.actor_to_follow = player
				party_member2.p_det_timer.timeout.disconnect(party_member2._check_for_player) 
				party_member2.name = str(CharDataKeeper.slot01.char_name)
				party_member2.p_det_timer.call_deferred("queue_free")
				party_member2.p_det_area.call_deferred("queue_free")
				
				var party_member3 : NPC = _NPC.instantiate()
				party_member3.npc_data = CharDataKeeper.slot02
				party_member3.is_following = true
				party_member3.collisions_on = false
				party_member3.global_position = player.global_position + Vector2(0,-1)
				CharDataKeeper.party_member_03 = party_member3
				scene_tree.add_child.call_deferred(party_member3)
				await get_tree().process_frame
				party_member3.actor_to_follow = CharDataKeeper.party_member_02
				party_member3.p_det_timer.timeout.disconnect(party_member3._check_for_player) 
				party_member3.name = str(CharDataKeeper.slot01.char_name)
				party_member3.p_det_timer.call_deferred("queue_free")
				party_member3.p_det_area.call_deferred("queue_free")
				

				var party_member4 : NPC = _NPC.instantiate()
				party_member4.npc_data = CharDataKeeper.slot03
				party_member4.is_following = true
				party_member4.collisions_on = false
				party_member4.global_position = player.global_position + Vector2(0,-1)
				CharDataKeeper.party_member_04 = party_member4
				scene_tree.add_child.call_deferred(party_member4)
				await get_tree().process_frame
				party_member4.actor_to_follow = CharDataKeeper.party_member_03
				party_member4.p_det_timer.timeout.disconnect(party_member4._check_for_player) 
				party_member4.name = str(CharDataKeeper.slot01.char_name)
				party_member4.p_det_timer.call_deferred("queue_free")
				party_member4.p_det_area.call_deferred("queue_free")
		party_is_made = true		
	pass



func _unhandled_input(_event):
	if Input.is_action_just_pressed("test1"):
		print(str(name) + " made player")
		make_player()
	if Input.is_action_just_pressed("test2"):
		print(str(name) + " made party")
		make_party()
