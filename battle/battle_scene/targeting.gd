class_name Targeting
extends RefCounted

enum FactionMode { SAME_AS_USER, OTHER_THAN_USER }

static func get_all_living_battlers(battle_scene : BattleScene) -> Array[Battler]:
	var out : Array[Battler] = []
	if battle_scene == null:
		return out
	if battle_scene.battlers == null:
		return out

	for n in battle_scene.battlers.get_children():
		if n is Battler:
			var b : Battler = n as Battler
			if b.actor_data == null:
				continue
			if b.actor_data.current_hp <= 0:
				continue
			out.append(b)

	return out


static func pick_random_living_ally(user : Battler, battle_scene : BattleScene, allow_self : bool = true, exclude : Array = []) -> Battler:
	if user == null:
		return null
	if battle_scene == null:
		return null

	var pool : Array[Battler] = []
	for b in get_all_living_battlers(battle_scene):
		if b == null:
			continue
		if b.faction != user.faction:
			continue
		if not allow_self and b == user:
			continue
		if exclude != null and exclude.has(b):
			continue
		pool.append(b)

	if pool.is_empty():
		return null

	return pool[randi_range(0, pool.size() - 1)]


static func pick_random_living_enemy(user : Battler, battle_scene : BattleScene, exclude : Array = []) -> Battler:
	if user == null:
		return null
	if battle_scene == null:
		return null

	var pool : Array[Battler] = []
	for b in get_all_living_battlers(battle_scene):
		if b == null:
			continue
		if b.faction == user.faction:
			continue
		if exclude != null and exclude.has(b):
			continue
		pool.append(b)

	if pool.is_empty():
		return null

	return pool[randi_range(0, pool.size() - 1)]




enum RetargetPolicy {
	NONE,
	SAME_FACTION_AS_USER,
	OTHER_FACTION_THAN_USER,
	SAME_FACTION_AS_TARGET,
	ANY_FACTION
}

static func is_living(b : Battler) -> bool:
	if b == null:
		return false
	if b.actor_data == null:
		return false
	return b.actor_data.current_hp > 0

static func get_all_living_battlers_in_faction(battle_scene : BattleScene, faction : int, exclude : Array = []) -> Array[Battler]:
	var out : Array[Battler] = []
	if battle_scene == null:
		return out

	for b in get_all_living_battlers(battle_scene):
		if b == null:
			continue
		if b.faction != faction:
			continue
		if exclude != null and exclude.has(b):
			continue
		out.append(b)

	return out

static func pick_random_living_any(battle_scene : BattleScene, exclude : Array = []) -> Battler:
	if battle_scene == null:
		return null

	var pool : Array[Battler] = []
	for b in get_all_living_battlers(battle_scene):
		if b == null:
			continue
		if exclude != null and exclude.has(b):
			continue
		pool.append(b)

	if pool.is_empty():
		return null

	return pool[randi_range(0, pool.size() - 1)]

static func pick_random_living_in_faction(battle_scene : BattleScene, faction : int, exclude : Array = []) -> Battler:
	var pool : Array[Battler] = get_all_living_battlers_in_faction(battle_scene, faction, exclude)
	if pool.is_empty():
		return null
	return pool[randi_range(0, pool.size() - 1)]

static func retarget_if_dead(user : Battler, battle_scene : BattleScene, target : Battler, policy : int, allow_self : bool = true, exclude : Array = []) -> Battler:
	if is_living(target):
		return target

	match policy:
		RetargetPolicy.NONE:
			return null

		RetargetPolicy.SAME_FACTION_AS_USER:
			return pick_random_living_ally(user, battle_scene, allow_self, exclude)

		RetargetPolicy.OTHER_FACTION_THAN_USER:
			return pick_random_living_enemy(user, battle_scene, exclude)

		RetargetPolicy.SAME_FACTION_AS_TARGET:
			if target == null:
				return null
			return pick_random_living_in_faction(battle_scene, target.faction, exclude)

		RetargetPolicy.ANY_FACTION:
			return pick_random_living_any(battle_scene, exclude)

	return null
