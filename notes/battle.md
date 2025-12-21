Major Examples:
Final Fantasy 4, 5, 6 (ATB)
Chrono Trigger (ATB)
Dragon Quest (Turn Based)
MM Battle Network (Real-Time, Grid Based)
LiveALive (Tactical, Grid Based)
Undertale (Turn Based, Active Elements)
Deltarune (Turn Based, Active Elements) #Player always acts first
MarioRPG (Turn Based, Active Elements)
Lufia (Turn Based, DQ with sprites)
Star Ocean (Real-Time with commands)
Paladins Quest (Turn Based) #DQ Style
Pokemon (Turn Based) #1v1

var _enemies
var _party
var _actor

How does battle work?


Normally...
_enemies to be encountered are held in a Resource that has an array, holding _enemies resources
Player walks around, finds _enemies in the field
_enemies can be invisible (FF / DQ / Undertale / LiveALive), 
	represented on-screen and engage the player (Mother 2/3 / Deltarune / MarioRPG)
	or the player walks into an area and the _enemies "come out" (Chrono Trigger)
Battle begins

#What happens when battle begins?
#scene transition happens
battle_scene_transition()
	gather_actor_stats()
		#_actor stats are gathered
	#_party base stats held in global variable, type Resource
		#_party modified stats held in global variable
	#_enemies base stats held in the list of enemies to be encountered's Array[EnemyResource]
	 	#_enemies modified stats determined by a difficulty level or modifier float
	
	#Turn order of _actor (_party + _enemies) is determined
	 first_turn_setup()
	 	is_anyone_surprised()
			var enemysurprised = false
			var partysurprised = false
			##needs something to determine who is surprised if they are.
			##If enemies are visible and chase the player, then engaging from the back can determine this
			##Player can sneak up on the enemy somehow, too
			##Certain enemies cannot be sneaked
			##Possibly some boss battles will start as surprised to give player a disadvantage
		#battle may start with _enemies or _actor having intiative-surprised (random roll)
		#in which case all _enemies or all _party goes before the opposing force
			#OR the opposing force cannot act during the first turn
	if enemysurprised == false and partysurprised == false:
		determine_turn_order()
			Usually by speed/agility stat
				Systems still "roll for initiative" (D&D style), and THEN use the speed stat
				(random roll + speed)
					re-roll or use secondary stat in event of a tie during the roll
						speed, strength, endurance, magic, HP, MP
			_actor are added to actor_list[] (probably an array) for the round happening

if in turn-based battle...
	_party (player) actions are selected
	actions are taken when player finishes selection
	"defend" commands happen only at the time the party member can act
if in ATB-type battle...
	_party + _enemies act when their "bar" is full
	"defend" command happens as soon as it is selected

 "defend" should last until the next time the _actor takes a turn
 	sometimes it only lasts until the end of the current round (which is not good)

When it is an _actor turn...
	current_actor = actor_list[0]
	perform_current_actor_turn(current_actor)
	It is determined if the _actor can perform an action
		cannot perform action if sleep/paralyze/etc
		goes to next turn
	Any effects that possibly prevent the current turn from happening random roll
		example: _actor is distracted/confused and MAY act or may not
	##If actor is affected by effects they can break out of, random roll to determine if they do
	status_effect_tick()
		if _actor.is_asleep == true:
			##example: Character is asleep, they may wake up
			var breakout = randi_range(0,100) #roll a random number
			if breakout >= somenumber
				_actor.is_asleep == false
	##If actor is affected by a dot_effect
	dot_effect_tick()
		if _actor.poison_tick > 0 or _actor.fire_tick > 0:
			poison_tick(_actor), fire_tick(_actor) #apply dot damage here
			_actor.poison_tick -= 1, _actor.fire_tick -= 1 #decrement tick count each round
			if _actor.dot_effect == 0:
				#dot effect ends
	action_is_taken()
		if enemy is not disabled:
			enemy_determines_action_to_take()
		else:
			next_actor_turn()
		actor_performs_action()
			if action is offensive:
				enemy_picks_target()
				if the action hits the target based on aggressor/defenders stats and random roll
					how much damage the target resisted (armor/magic resist) based on aggressor/defender stats and random roll
					applies a counter for effects that persist for multiple turns
				if target.HP <= 0: #HP typically does not show less than 0, but maybe should
					target.death()
				else:
					continue
			if action is defensive:
				_actor_performs_defensive_action(target)
			await action_finished
			next_actor_turn()



How battle is handled:
	Enemies run around the field, once they are in alert mode, they chase the controlled party member. 
	Once the enemy touches the controlled party member, GameState changes to BATTLE (2)
	the enemy scene bumping into the party member is saved in a variable (so it can be deleted once it is defeated, should probably done by the enemy itself, but called by the battle system)
	The enemy's enemy_group is recorded in a variable within the battle system in order to instantiate the enemies for battle.
	scene transition called to hide scene change (plays beginning transition)
	main.field_root is hidden and paused 
	
	battle system instantiates enemies within the battle scene
	battle system draws players
	battle system draws UI
	battle system figures out turn order
	scene transition finishes (plays end transition)
	battle starts
	All actors take turns in order until one side(party or enemy party) is dead
	Assuming the party is victorious (usually), loot/experience is given.
	scene transition called to hide scene change (plays beginning transition)
	battle scene queue free'd
	main.field_root is unhidden and unpaused
	enemy calls a destroy function
	scene transition finishes (plays end transition)
