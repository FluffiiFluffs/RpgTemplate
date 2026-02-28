## Currently the dialogue system's authoring process is a little too much. I would like to refactor it.
## Right now, authored dialogue looks like this: 
## 	NPC1: [do set_portrait("npc", "normal")]Hello stranger. It looks like you do not have this quest yet. Go talk to the other NPC over there. I gave you a quest.

##The problem is with [do set_portrait("npc", "normal")]
## The changes I would like to implement would change this dialogue line to this:
## 	NPC1: Hello stranger. It looks like you do not have this quest yet. Go talk to the other NPC over there. I gave you a quest.

## SpeakerResource has been changed dramatically, currently the dialogue system will not work correctly due to these changes,

## Proposed changes
	## Within dm_helper 
		## Append all SpeakerResource resources to an array within global script dm_helper (it is already an autoload and all dialogue should be "using DM". This array should not be within the dialogue_manager's autoload itself so it can be a separate thing (and survive updates if needed)
	 	
		## helper function for finding, and returning a SpeakerResource by ID
		## helper function for returning a mood portrait (close and open) for the speaker
		## helper function for returning the display name of the speakerid
		## helper function for returning pronouns for the speakerid
		## helper function for returning the voice of the speakerid
		## helper function for setting voice pitch for the speakerid (min/max)

## So from the above example, NPC1 would be the identifier for the speakerid
## The dialogue system searches within dm_helper.all_speakers to match the ID
## Then, dm_helper functions are called to set up the next line of text within the balloon
## optionally the [#mood=] tag can be used to override the portrait set used
	## If no mood tag is set, then normal default is used
## If no portraits are set within the SpeakerResource, then no portrait is shown
## If a normal portrait exists, and a mood is called but the speaker resource does not have anything set for that mood, then the default normal is used
	## If a mood is called, but no normal portrait is set, then no portrait is shown
	## To show a portrait, the speaker resource must have at least a normal portrait set
## If Options.portrait_type is set to TALKING and no "open" portrait exists, then only the closed portrait is used
## If Options.portrait_type is set to STILL, then only the "close" portrait is used within the dialogue system
## If no voice file is set within the SpeakerResource, then a default voice will be used
	## This default voice should be DM.default_voice
	
## With these changes, authoring time should be cut down substntially since the author only has to match a speaker ID, and optionally a mood

## These variables within dialogue manager should become unused:
	## var speaker_resources : Array[SpeakerResource]
	## var current_balloon
	## var speaker_current_expression : Texture
	## var speaker_normal_expression : Texture
	## var speaker_talk_expression : Texture
	## var speaker_sad_expression : Texture
	## var speaker_surprise_expression : Texture
	## var speaker_angry_expression : Texture
	## var speaker_happy_expression : Texture
	## var speaker_special_expression : Texture
	## var speaker_tired_expression : Texture
	## var speaker_voice : AudioStream
## dm_helper should instead be the one to manage these.	
