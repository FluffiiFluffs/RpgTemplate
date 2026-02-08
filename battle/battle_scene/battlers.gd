class_name Battlers
extends Node
##battlers.gd
##Script attached to Battlers node within battle_scene.tscn

#Reference to the parent battle scene
var battle_scene = null

##Battler node preload for instantiation
const BATTLER = preload("uid://cjqlo5m6a50x2")



func _ready()->void:
	battle_scene = get_parent() #Gets parent battle scene when this node loads

##For when battle starts
##Instantiates battler nodes under battlers node
##Assigns battler to turn order array (unsorted)
func make_battlers()->void:
	for child in CharDataKeeper.party_members:
		if child == null:
			continue
		child.rebuild_base_stats()
	
	for child in CharDataKeeper.party_members:
		var new_battler : Battler = BATTLER.instantiate()
		new_battler.actor_data = child
		if child.battle_scene != null:
			new_battler.battler_scene = child.battle_scene
		else:
			printerr(name +": " + str(child.get_display_name()) + " No Battle Scene!")
		if child.battle_icon != null:
			new_battler.battler_icon = child.battle_icon
		else:
			printerr(name +": " + str(child.get_display_name()) + " No Battle Icon!")
		add_child(new_battler)
		new_battler.name = child.get_display_name()
		new_battler.faction = Battler.Faction.PARTY
		battle_scene.turn_order.append(new_battler)
		new_battler.tie_roll = randi()

	if battle_scene.enemy_group.enemies.is_empty():
		printerr(name +": " + "enemy_group is empty!!")
	else:
		for i in range(battle_scene.enemy_group.enemies.size()):
			var template : EnemyData = battle_scene.enemy_group.enemies[i]
			if template == null:
				continue

			var runtime_data : EnemyData = template.duplicate(true) as EnemyData

			# Runtime state must be unique per battler
			runtime_data.status_effects = []
			runtime_data.current_hp = runtime_data.get_max_hp()
			runtime_data.current_sp = runtime_data.get_max_sp()

			var new_battler : Battler = BATTLER.instantiate()
			new_battler.actor_data = runtime_data
			add_child(new_battler)

			# Optional clarity in debugger and node tree
			var runtime_name : String = runtime_data.get_display_name()
			if runtime_name == "":
				runtime_name = "Enemy"
			new_battler.name = runtime_name + "_" + str(i)

			if template.battle_scene != null:
				new_battler.battler_scene = template.battle_scene
			else:
				printerr(name + ": " + str(template.get_display_name()) + " No Battle Scene!")

			if template.battle_icon != null:
				new_battler.battler_icon = template.battle_icon
			else:
				printerr(name + ": " + str(template.get_display_name()) + " No Battle Icon!")

			new_battler.faction = Battler.Faction.ENEMY
			battle_scene.turn_order.append(new_battler)
			new_battler.tie_roll = randi()



##Adds battlers to the battle_scene.turn_order[], but does NOT sort them.
func add_battlers_to_turn_order()->void:
	for child in get_children():
		if child is Battler:
			battle_scene.turn_order.append(child)
