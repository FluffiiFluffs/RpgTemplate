##Used to parse text in order to be used as an arguement within the
	##battle_system.battle_notify_ui.queue_notification()
##[br]
##Supported tokens: {user}, {targets}, {skill}, {item}
##[br]
##Tokens must be in all lowercase to work.
class_name TextParser
extends Node

var battle_scene : BattleScene = null


func parse_skill_message(use: ActionUse, skill: Skill) -> String:
	var template = "{user} uses {skill}."
	if skill != null:
		template = skill.message_template
	return parse_template(template, use, skill, null)


func parse_item_message(use: ActionUse, item: Item) -> String:
	var template = "{user} uses {item}."
	if item != null:
		template = item.message_template
	return parse_template(template, use, null, item)


func parse_template(template: String, use: ActionUse, skill: Skill, item: Item) -> String:
	if use == null:
		return _normalize_whitespace(template)

	var out = template

	var user_name = _battler_name(use.user)
	out = out.replace("{user}", user_name)

	var target_names = _collect_target_names(use.targets)
	var targets_text = _format_targets(target_names)
	out = out.replace("{targets}", targets_text)

	var first_target = ""
	if use.targets.size() > 0:
		first_target = _battler_name(use.targets[0])
	out = out.replace("{target}", first_target)

	if skill != null:
		out = out.replace("{skill}", skill.name)
	else:
		out = out.replace("{skill}", "")

	if item != null:
		out = out.replace("{item}", item.name)
	else:
		out = out.replace("{item}", "")

	out = _normalize_whitespace(out)
	return out


func _battler_name(battler: Battler) -> String:
	if battler == null:
		return ""
	if battler.actor_data == null:
		return ""
	if battler.actor_data.char_resource == null:
		return ""
	return battler.actor_data.char_resource.char_name


func _collect_target_names(targets: Array[Battler]) -> Array[String]:
	var names: Array[String] = []
	for t in targets:
		var n = _battler_name(t)
		if n != "":
			names.append(n)
	return names


func _format_targets(names: Array[String]) -> String:
	var count = names.size()
	if count <= 0:
		return ""
	if count == 1:
		return names[0]
	if count == 2:
		return names[0] + " and " + names[1]

	var out = ""
	var i = 0
	while i < count:
		if i == count - 1:
			out = out + "and " + names[i]
		else:
			out = out + names[i] + ", "
		i += 1
	return out


func _normalize_whitespace(text: String) -> String:
	var out = text

	while out.find("  ") != -1:
		out = out.replace("  ", " ")

	out = out.replace(" .", ".")
	out = out.replace(" ,", ",")
	out = out.replace(" !", "!")
	out = out.replace(" ?", "?")

	return out.strip_edges()
