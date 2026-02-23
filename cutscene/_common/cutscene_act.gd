class_name CutsceneAct extends Resource

enum Playtype {SEQUENCE, PARALLEL}

@export var playtype : Playtype = Playtype.SEQUENCE
@export var cutscene_actions : Array[CutsceneAction] = []
