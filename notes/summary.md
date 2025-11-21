2D Top Down RPG

Resolution 398x224

Free Movement with walk/run
Tile Size: 16x16
Character Size: ~16x36
Possible Action Elements

Battle
Hidden ATB Turn Based

Dialog
Dialog Manager

Quest System

- - - - - - - - - - - - - - - - 

[Dialog Facing]
	CT : Character must face the speaker, but can be some distance away. Can be off-center slightly. Player can walk around if non-merchant and dialogue is non-important.
	Mother 2 : Character can stand on the adjacent tile and the speaker will trigger dialogue. Must be lined up N/S/E/W.
	Mother 3 : Character must face the speaker. Can be off-center slightly.
	DQ : Character must face the speaker
	Zelda LTTP : Character must face the speaker. Can be off-center slightly.
	Pokemon : Character must face the speaker.
	FF6 : Character must face the speaker. Character must be 1 tile away (except merchants)
	Mario RPG : Character must face the speaker. Character can be off-center.

[Camera Constraints]
	CT : Camera constrains to tileset size, but often the character is limited by a collision before that happens
	Mother 2 : Camera does not seem to constrain to the tileset at all.
	Mother 3 : Camera does not seem to constrain to the tilset at all.
	DQ : Camera does not seem to constrain to the tilset.
	Zelda LTTP : Camera constrains to tilset.
	Pokemon : Camera does not seem to constrain to the tileset.
	FF6 : Camera is not constrained by the tilset.
	Mario RPG : Camera constrained in some places by tileset.
	
[Horizontal Stairs]
	CT : Yes. Act as ramps. Forces diagonal movement. No input needed.
	Mother 2 : [not sure]
	Mother 3 : Yes. Ramps. Forces diagonal movement. No input needed.
	DQ : No. All Stairs are either a single tile or vertical only. Used for scene change.
	Zelda LTTP: No. Vertical stairs, act as ramps that slow the player down.
	Pokemon. Same as DQ.
	FF6 : Yes. Character moves (1,1) in the direciton they were moving. Step animation double per one 'move'
	Mario RPG : Stairs any direction. Player must use correct inputs to traverse.
	
[Battle System]
	CT : ATB. Enemies roam static areas. No new scene. Characters battle in-field (but not on world map). 
	Mother 2 : Turn based. Enemies spawn and roam static areas. Characters battle in separate scene (windows)
	Mother 3 : Turn based. Enemies spawn and roam static areas. Characters battle in separate scene (windows)
	DQ : Turn based. Invisible enemies. Characters battle in separate scene (windows)
	Zelda LTTP : Action. Same enemies spawn from the same points.
	Pokemon : Turn based. Invisible enemies. Characters battle in slightly animated scene.
	FF6 : ATB. Mostly-Invisible enemies. Characters battle in separate scene with animations.
	Mario RPG : Turn based. Enemies spawn and roam static areas. Characters battle in separate scene with animations.
