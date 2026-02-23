Requirements
	Needs to be driven by an autoload API (CutsceneManager)
	Must be able to control actors (movement, animations, states)
		position uses CutsceneMarker ID
	Must be able to control camera (which is main, position, )
		position uses CutsceneMarker ID
	Must be able to drive dialogue
	Entry Points must be:
		non-player-driven (intro sequence)
		dialougue
		area entered (CutSceneArea)


Parts of the System: 
	CutsceneManager : Autoload Script = drives cutscenes
		cutscenes_in_scene : Array[CutSceneScript] = holds reference to all cutscenes within the scene
		
	CutsceneMarker : Marker2D = Instantiated scene used to move something to the location with the cutscene manager
	
	CutsceneArea : Area2D = Instantiated used to trigger a cutscene when the controlled character walks into it
		
	CutsceneScript : Node = has Array holding CutsceneActs. CutsceneActs are played in order. Overall capsule for all actions within the cutscene. Held within a node so it can be called by other scripts easily and saved as a scene for reuse if needed.
		Acts : Array[CutsceneAct] = array holding CutSceneActs. Played in sequence only.
		one_shot : bool = if false cutscene can be played multiple times on trigger
		has_been_played : bool = if true and oneshot, then cutscene will not trigger again
	
	CutsceneAct : Resource = Array holding CutsceneActions. Plays CutsceneActions. CutsceneActions can be played in parallel or sequence.
	
	CutsceneAction : Resource = (other resources inherit from this object)
		CutsceneCameraMove : extends CutsceneAction
			pathtype : 1 = straight line from point to point, 2 = use navigation, 3 = instant
			camera_id : ID of camera to be moved
			
		CutsceneActorMove : extends CutsceneAction
			pathtype : 1 = straight line point to point, 2 = use navigation, 3 = instant
			field_actor_id : String = ID of field actor to be moved
			
		CutsceneDialogue : extends CutsceneAction
			dialogue_resource : Resource = exported dialogue file to be used
			speakers : Array[SpeakerResource] = array holding speaker resources to be used within dialogue
			dialogue_start : String =  where to start dialogue within the dialogue file
		
		CutsceneInstantiate : extends CutsceneAction
			scene : PackedScene = which scene to instantiate
			
		CutsceneChangeScene : extends CutsceneAction
			scene_to : PackedScene = which scene to change to
		
		CutsceneSoundEffect : extends CutsceneAction
			sound_effect := Sound to be played
			
		CutsceneMusic : extends CutsceneAction
			music := Music to be played
			
		CutsceneApplyStatus : extends CutsceneAction
			status : string = status effect ID to be placed
			actor_id : actor_id for status to be placed (in their actor_data)
			
		CutscenGiveItem (maybe better to do this through the dialogue manager since functionality already exists)
			should also include removing items
		
