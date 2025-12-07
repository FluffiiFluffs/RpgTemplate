class_name ItemEffect
extends Resource
##Base class for all other item effects


##Checks if the item can be used on the party member
func can_use_on_member(_member : PartyMemberData)->bool:
	return true

##Apply the effect to the party member
##returns true if something actually changed
func apply_to_member(_member: PartyMemberData)->bool:
	return false
