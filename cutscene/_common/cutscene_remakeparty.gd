class_name CutsceneRemakeParty
extends CutsceneAction
## Records position of all party member field scenes currently present in the active field scene.
## Rebuilds the field party in the order found in CharDataKeeper.party_members.
## If a member does not already have a recorded field position, they are placed 1 pixel above the leader position.
## Used after the party order changes or a party member is added during gameplay.
