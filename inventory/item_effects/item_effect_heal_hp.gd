class_name ItemEffectHealHP
extends ItemEffect

##INHERITED FROM ItemEffect

#func can_use_on_member(_member : PartyMemberData)->bool:
	#return true

#func apply_to_member(_member: PartyMemberData)->bool:
	#return false




##How much to heal for
@export var hp_heal_amount : int = 0

##Checks if exists, dead, or full hp. if not, then returns true
func can_use_on_member(_member : PartyMemberData)->bool:
	if _member == null: #not found
		return false
	if _member.current_hp <= 0: #dead
		return false 
	if _member.current_hp >= _member.get_max_hp(): #hp is full
		return false
	return true

##Heals member by hp_heal_amount, does not exceed member's max_hp
##Returns true if HP was changed
func apply_to_member(_member: PartyMemberData)->bool:
	if not can_use_on_member(_member):
		print("CANNOT USE ON " + _member.char_resource.char_name + " (error sound)")
		GameMenu.play_error_sound()
		return false
	var before_hp = _member.current_hp
	var new_hp = _member.current_hp + hp_heal_amount
	if new_hp > _member.get_max_hp():
		new_hp = _member.get_max_hp()
		
	_member.current_hp = new_hp
	return _member.current_hp != before_hp
