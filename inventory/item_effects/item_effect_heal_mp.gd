class_name ItemEffectHealMP
extends ItemEffect

##INHERITED FROM ItemEffect

#func can_use_on_member(_member : PartyMemberData)->bool:
	#return true

#func apply_to_member(_member: PartyMemberData)->bool:
	#return false




##How much to heal for
@export var mp_heal_amount : int = 0

##Checks if exists, dead, or full mp. if not, then returns true
func can_use_on_member(_member : PartyMemberData)->bool:
	if _member == null: #not found
		return false
	if _member.current_mp <= 0: #dead
		return false 
	if _member.current_mp >= _member.get_max_mp(): #mp is full
		return false
	return true

##Heals member by mp_heal_amount, does not exceed member's max_mp
##Returns true if HP was changed
func apply_to_member(_member: PartyMemberData)->bool:
	if not can_use_on_member(_member):
		GameMenu.play_error_sound()
		return false
	var before_mp = _member.current_mp
	var new_mp = _member.current_mp + mp_heal_amount
	if new_mp > _member.get_max_mp():
		new_mp = _member.get_max_mp()
		
	_member.current_mp = new_mp
	return _member.current_mp != before_mp
