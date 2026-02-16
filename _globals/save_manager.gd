##save_manager.gd
##global class SaveManager
extends Node2D




#Arrays needing to be populated to rebuild a save during load
	#all skills list
		#needs script to populate array from files
	#all battleactions list
		#needs script to populate array from files
	#all status effects list
		#needs script to populate array from files
	#all quests list
		#needs script to populate array from files
	#all items list
		#needs script to populate array from files
	#all party members (already populated by hand. Reasonable due to low amount of possible party members)
#Battleactions, skills, and status effects should be okay to "just pull" from this list since they're defined in resources and any special cases would simply just be a different resouce with a different ID


##Things to save/load
#Options
	#music volume
	#sfx volume
	#voices volume
	#item sort order array
	#voices type
	#portrait type
	#always run
	#message speed
	#battle message speed
	#menu memory
	#battle menu memory
	#enemies killed
	#party member deaths
	#items used
	#skills used
	#times saved (should be incremented when a save is generated)
	#time loaded (should be incremented when the game is loaded, but not increment times saved
	#quests completed
	#time played




#current scene (should probably use a filename string or UID for this)
	#position in scene
		#don't need to record the party, they should just spawn behind the player as normal

#CharDataKeeper Data

	#members in the party (partymemberdata)
		#Position in CharDataKeeper.party_member array so it can be repopulated accurately
			#first party member should be the one that is set to is_controlled and that should be reflected during repopulation within chardatakeeper
	
	#outside_members should be recorded, too
	
		#actor_data
			#current_exp
			#next level exp
			#total exp
			#display name
			#level
			#base_stats
				#max hp
				#max sp
				#atk value
				#def value
				#matk value
				#mdef value
				#strength
				#stamina
				#agility
				#magic
				#luck
			#current HP
			#current sp
			#status effects
			#Equipment
			#two handing true/false
			#battle_actions
				#needs_id to rebuild
			#skills
				#use skill ID to rebuild
			#normal_attack_skill
			#can_dodge true/false
			#can_parry true/false
	
	#money

#inventory
	#slots and items in those slots, probably needs a dictionary
	
#Quests
	#current quests
	#completed quests
	#Per Quest ID
		#current_step
		#is completed
		#repeatable
		#steps array (needs ID to repopulate easily)
			#actions taken
			#is completed


#Persistence data
	#recorded per scene
	#if special enemies were killed
	#if certain chests were opened
	#locked doors
	#if certain people have been talked to
	#One time events
	
