# Cutscenes

This document describes the cutscene system currently implemented in the project, based on the runtime behavior in `RpgTemplate/_globals/cutscene_manager.gd` and the data authored under `RpgTemplate/cutscene/_common/`.

## Goals and scope

1. Provide a scene authored cutscene system driven by an autoload API (`CutsceneManager`)
2. Support deterministic sequencing and parallel execution for authored actions
3. Support actor control and camera control using `CutsceneMarker` ids
4. Support dialogue playback through DialogueManager
5. Support scene transitions during cutscenes using SceneManager

## Authoring components

### CutsceneManager (autoload)
`RpgTemplate/_globals/cutscene_manager.gd`

Responsibilities

1. Register the active `FieldScene`
2. Cache `CutsceneScript` nodes and `CutsceneMarker` nodes found in that scene
3. Play a cutscene by id, executing acts and actions with `await` driven sequencing
4. Optionally force actors into `CutsceneState` while a cutscene runs, then restore their prior states
5. Track camera rigs touched by cutscene camera actions so rig process settings and follow tuning can be restored

Signals

1. `cutscene_start(cutscene_id : StringName)`
2. `cutscene_end(cutscene_id : StringName)`

Execution gate

1. Only one cutscene runs at a time
2. If `_is_playing` is true, additional `play_cutscene()` calls return immediately

### CutsceneScript (Node)
`RpgTemplate/cutscene/_common/cutscene_script.gd`

Exports

1. `cutscene_id : StringName`
2. `one_shot : bool`
3. `has_been_played : bool`
4. `acts : Array[CutsceneAct]`
5. `pause_entities : PENTITIES`

`pause_entities` controls which actors are forced into `CutsceneState` and whether `GameState` is switched to `CUTSCENE`.

PENTITIES modes

1. `ALL` forces `CutsceneState` on every `FieldActor` found in the active `FieldScene`
2. `PLAYER` forces `CutsceneState` on the controlled character and any actors referenced by this cutscene's actions
3. `NONE` does not force `CutsceneState` and does not switch `GameState` to `CUTSCENE`

Editor behavior

1. In editor, `cutscene_id` is kept equal to the node name

### CutsceneAct (Resource)
`RpgTemplate/cutscene/_common/cutscene_act.gd`

Exports

1. `playtype : Playtype`
2. `cutscene_actions : Array[CutsceneAction]`

Playtype modes

1. `SEQUENCE` runs each action in order, awaiting each one
2. `PARALLEL` launches all actions and awaits completion of all of them

Special case

1. A `PARALLEL` act containing `CutsceneChangeScene` is executed as `SEQUENCE` to avoid destroying the running scene while other actions still execute

### CutsceneAction (Resource base)
`RpgTemplate/cutscene/_common/cutscene_action.gd`

Concrete action resources derive from this and hold only data. Execution is performed by `CutsceneManager`.

### CutsceneMarker (Marker2D)
`RpgTemplate/cutscene/_common/cutscene_marker.gd`

Purpose

1. Provides authored positions for actor movement, camera movement, and instantiation locations

Identity

1. Marker ids are looked up by `marker_id` when set, otherwise by node name
2. In editor, `marker_id` is kept equal to the node name

### CutsceneArea (Area2D trigger)
`RpgTemplate/cutscene/_common/cutscene_area.gd`

Exports

1. `one_shot : bool`
2. `has_played : bool`
3. `cutscene_id : StringName`

Runtime behavior

1. Only the controlled character triggers the cutscene
2. When triggered, it calls `CutsceneManager.play_cutscene(cutscene_id)`
3. It has its own one shot gating independent of `CutsceneScript.one_shot`

## Identification and lookup rules

CutsceneScript id resolution used by CutsceneManager

1. Prefer `CutsceneScript.cutscene_id` when not empty
2. Otherwise use the node name

CutsceneMarker id resolution used by CutsceneManager

1. Prefer `CutsceneMarker.marker_id` when not empty
2. Otherwise use the node name

CutsceneManager caching

1. On `register_field_scene(fscene)`, the manager traverses the field scene tree and caches all `CutsceneScript` and `CutsceneMarker` nodes
2. Duplicate ids are reported as authoring errors

FieldActor lookup

1. Actor lookup for cutscene actions is done by scanning the current field scene tree for a `FieldActor` whose `field_actor_id` matches the requested id
2. Actors do not have to be pre registered with the cutscene system

## Entry points

1. `CutsceneArea` on body enter (controlled character only)
2. Dialogue scripts that call `CutsceneManager.play_cutscene(...)`
3. Any script that calls `CutsceneManager.play_cutscene(cutscene_id)`

## Runtime lifecycle

### One shot gate
If `CutsceneScript.one_shot` is true and `has_been_played` is already true, the cutscene returns without running actions.

### GameState handling
When `pause_entities` is not `NONE`

1. `GameState.gamestate` is set to `GameState.State.CUTSCENE`
2. At cutscene end, GameState is restored to the prior value with additional handling for dialogue launched cutscenes

Dialogue launched restoration logic

1. If the prior state was `DIALOGUE`, the manager yields one frame and checks for an active `DialogBalloon`
2. If a balloon is still active, the manager restores `DIALOGUE`
3. Otherwise the manager restores `FIELD`

When `pause_entities` is `NONE`

1. The manager does not change `GameState.gamestate`

### Actor pause and restore
When pausing is enabled (`pause_entities` is `ALL` or `PLAYER`)

1. The manager forces selected actors into the `CutScene` state by calling `StateMachine.force_state_by_name("CutScene")`
2. The manager stores each actor's previous state (`StateMachine.current_state`) so it can be restored at the end

Actor selection

1. `ALL` selects all `FieldActor` nodes in the current `FieldScene`
2. `PLAYER` selects the controlled character, plus actor ids referenced by actions
   1. Currently referenced actor ids are collected from `CutsceneActorMove.actor_id` when `move_controlled_character` is false
   2. Currently referenced actor ids are collected from `CutsceneQueueFree.target_id`

Restoration safety

1. During restore, the manager checks `is_instance_valid()` on the stored `StateMachine` and prior `State` before attempting to restore
2. `CutsceneQueueFree` removes its target from the restore list before freeing it

### Camera override tracking
Camera actions register the camera rig in `_camera_override_entries` so the manager can restore

1. Rig `process_mode`
2. `FieldCameraRig.follow_speed` and `FieldCameraRig.snap` unless a follow action requests persistence

At cutscene end, the manager restores rig settings. It does not automatically retarget the camera to the controlled character. Camera follow behavior is authored via `CutsceneCameraFollow`.

## Action reference

This section documents actions currently executed by `CutsceneManager._run_action()`.

### CutsceneActorMove
Resource: `RpgTemplate/cutscene/_common/cutscene_actormove.gd`

Exports

1. `path_type : PathType` (`STRAIGHT_LINE`, `NAVIGATION`, `INSTANT`)
2. `move_controlled_character : bool`
3. `actor_id : String`
4. `move_location_ids : Array[StringName]`
5. `move_speed : float`

Runtime behavior

1. If `move_controlled_character` is true, the target actor is `CharDataKeeper.controlled_character`
2. Otherwise the manager resolves a `FieldActor` by `field_actor_id == StringName(actor_id)`
3. Each `move_location_id` is resolved to a `CutsceneMarker`, then the actor is moved to the marker position in order
4. The actor is asked to face the movement direction via `actor.force_face_direction(target_pos - actor.global_position)`
5. Movement implementation
   1. `INSTANT` sets `global_position` immediately
   2. Other path types currently tween `global_position` using `move_speed` as pixels per second

### CutsceneCameraMove
Resource: `RpgTemplate/cutscene/_common/cutscene_cameramove.gd`

Exports

1. `path_type : PathType` (`STRAIGHT_LINE`, `NAVIGATION`, `INSTANT`)
2. `camera_rig_id : StringName`
3. `transition_type : Tween.TransitionType`
4. `easing_method : Tween.EaseType`
5. `move_location_ids : Array[StringName]`
6. `move_speed : float`

Runtime behavior

1. Resolve the camera rig
   1. Default `FieldCameraRig` is returned when `camera_rig_id` is empty or equals `"FieldCameraRig"`
   2. Otherwise a `Node2D` is found under `Main` by node name, with a secondary probe for a `camera_rig_id` property
2. For each marker id, the rig is moved to the marker position in order
3. Movement implementation
   1. `INSTANT` sets `global_position` immediately
   2. `NAVIGATION` is treated as straight line and emits a warning
   3. Tween motion uses `move_speed` as pixels per second, `transition_type`, and `easing_method`
   4. The tween pause mode is process based so it continues even while the game is in cutscene state

### CutsceneCameraFollow
Resource: `RpgTemplate/cutscene/_common/cutscene_camerafollow.gd`

Exports

1. `camera_rig_id : StringName`
2. `follow_controlled_character : bool`
3. `actor_id : StringName`
4. `do_transition_to_target : bool`
5. `path_type : PathType`
6. `transition_type : Tween.TransitionType`
7. `easing_method : Tween.EaseType`
8. `move_speed : float`
9. `snap_on_follow_start : bool`
10. `override_follow_settings : bool`
11. `follow_speed : float`
12. `snap : bool`
13. `persist_follow_settings : bool`

Runtime behavior

1. Resolve the camera rig as in `CutsceneCameraMove`
2. Resolve the follow target
   1. If `follow_controlled_character` is true, target is the controlled character
   2. Otherwise the target is the `FieldActor` matching `actor_id`
3. If the rig is `FieldCameraRig`
   1. Optional override of follow tuning (`follow_speed`, `snap`)
   2. Optional transition to the target position by temporarily disabling follow, activating the rig, then running a camera move to the target position
   3. After optional transition, set the follow target with `set_target(target, snap_on_follow_start)`
4. If the rig is not `FieldCameraRig`
   1. Optional transition is performed by moving the rig to the target position using the camera move helper
   2. If the rig has a `set_target` method, it is called with the target and snap flag

### CutsceneDialogue
Resource: `RpgTemplate/cutscene/_common/cutscene_dialogue.gd`

Exports

1. `dialogue_resource : Resource`
2. `speakers : Array[SpeakerResource]`
3. `dialogue_start : String`

Runtime behavior

1. Sets DialogueManager resources to a duplicate of `speakers`
2. Shows a dialogue balloon for `dialogue_resource` starting at `dialogue_start`
   1. If `dialogue_start` is empty, `"start"` is used
3. Awaits `DialogueManager.dialogue_ended` until the ended resource matches the `dialogue_resource`

### CutsceneWait
Resource: `RpgTemplate/cutscene/_common/cutscene_wait.gd`

Exports

1. `wait_time : float`

Runtime behavior

1. If `wait_time` is less than or equal to 0, yields one frame
2. Otherwise creates a timer with process always enabled and awaits its timeout

### CutsceneInstantiate
Resource: `RpgTemplate/cutscene/_common/cutscene_instantiate.gd`

Exports

1. `type : TYPE` (`ACTOR`, `OBJECT`, `VFX`)
2. `instantiated_scene : PackedScene`
3. `instantiate_location_ids : Array[StringName]`
4. `target_id : StringName`

Runtime behavior

1. For each marker id, instantiate one instance of `instantiated_scene` and place it at the marker position
2. Parent selection
   1. `ACTOR` parents under `current_field_scene.field_actors` when present, otherwise under the field scene root
   2. `OBJECT` parents under `current_field_scene.interactables` when present, otherwise under the field scene root
   3. `VFX` parents under `Main.field_vfx` when present, otherwise under the field scene root
3. Id assignment
   1. If `target_id` is empty, no id is assigned
   2. If `type` is `VFX`, no id is assigned
   3. If `type` is `ACTOR` and the instance is a `FieldActor`, the manager sets `field_actor_id = target_id`
   4. If `type` is `ACTOR` and the instance is not a `FieldActor`, the manager attempts to set an `actor_id` property, then a `field_actor_id` property when present
   5. If `type` is `OBJECT`, the manager attempts to set an `object_id` property, then a `field_object_id` property when present
4. Interaction with pause mode
   1. When `pause_entities` is `ALL`, spawned actors are forced into `CutsceneState` after one frame
   2. When `pause_entities` is `PLAYER`, spawned actors are forced into `CutsceneState` after one frame when `type` is `ACTOR` and `target_id` is set

### CutsceneQueueFree
Resource: `RpgTemplate/cutscene/_common/cutscene_queuefree.gd`

Exports

1. `target_id : StringName`

Runtime behavior

1. Resolves a `FieldActor` by `field_actor_id == target_id`
2. Removes that actor from the stored restore list
3. Defers `queue_free()` and yields one frame

Current scope

1. The runtime implementation targets `FieldActor` ids. Objects are not supported by this action yet.

### CutsceneChangeScene
Resource: `RpgTemplate/cutscene/_common/cutscene_changescene.gd`

Exports

1. `scene_to_load : String` (tscn path via `@export_file("*.tscn")`)
2. `target_transition_area : String`

Runtime behavior

1. If a dialogue balloon exists, it is force closed to avoid leaving GameState stuck in dialogue during the scene load
2. Camera rig overrides are restored before the scene load call
3. The cutscene is aborted (`_abort_requested = true`) so no further acts run in the old scene
4. Cutscene actor restore entries are cleared because the leaving scene is expected to be freed
5. Calls `SceneManager.load_field_scene(scene_to_load, target_transition_area)` and awaits completion
6. Calls `SceneManager.set_field_enemies_paused(false)` after the load

## Defined actions that are not executed yet

These resources exist but currently do not run because `CutsceneManager._run_action()` has no dispatch for them.

1. `CutsceneActorAnimate` (`cutscene_actoranimate.gd`)
2. `CutsceneSFX` (`cutscene_sfx.gd`)
3. `CutsceneMusic` (`cutscene_music.gd`)
4. `CutsceneApplyStatus` (`cutscene_applystatus.gd`)

## Known limitations

1. No cutscene queueing or cancellation
2. Actor movement navigation is not implemented
3. Camera navigation is not implemented (treated as straight line with a warning)
4. CutsceneQueueFree currently resolves only `FieldActor` ids
5. CutsceneManager restores camera rig tuning and process mode, and does not automatically retarget follow to the controlled character
