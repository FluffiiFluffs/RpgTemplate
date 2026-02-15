class_name BattleVFX
extends Control

var battle_scene : BattleScene = null

const TEXTPOPUP = preload("uid://emit5otocxf1")

func pop_text(target : Battler, amount : int) -> void:
	var popup : TextPopup = TEXTPOPUP.instantiate()
	add_child(popup)
	popup.set_number(amount)
	popup.set_title("")
	popup.title_visible()
	popup.set_color(Color(1.0, 1.0, 1.0, 1.0))
	var point : Vector2 = target.ui_element.marker_2d.get_global_transform_with_canvas().origin.round()
	popup.snap_center_to_canvas_point(point)
	popup.show_text()
	
func pop_text_critical(target : Battler, amount : int) -> void:
	var popup : TextPopup = TEXTPOPUP.instantiate()
	add_child(popup)
	popup.set_number(amount)
	popup.set_title("CRITICAL")
	popup.set_color(Color(0.945, 0.704, 0.0, 1.0))
	popup.title_visible()
	var point : Vector2 = target.ui_element.marker_2d.get_global_transform_with_canvas().origin.round()
	popup.snap_center_to_canvas_point(point)
	popup.show_text()


func pop_text_riposte(target : Battler, amount : int) -> void:
	var popup : TextPopup = TEXTPOPUP.instantiate()
	add_child(popup)
	popup.set_number(amount)
	popup.set_title("RIPOSTE")
	popup.set_color(Color(0.945, 0.704, 0.0, 1.0))
	popup.title_visible()
	var point : Vector2 = target.ui_element.marker_2d.get_global_transform_with_canvas().origin.round()
	popup.snap_center_to_canvas_point(point)
	popup.show_text()

func pop_text_only(target : Battler, text : String )->void:
	var popup : TextPopup = TEXTPOPUP.instantiate()
	add_child(popup)
	popup.number_label.visible = false
	popup.set_title(text)
	popup.set_color(Color(1.0, 1.0, 1.0, 1.0))
	popup.title_visible()
	var point : Vector2 = target.ui_element.marker_2d.get_global_transform_with_canvas().origin.round()
	popup.snap_center_to_canvas_point(point)
	popup.show_text()

func pop_text_healing(target : Battler, amount : int) -> void:
	var popup : TextPopup = TEXTPOPUP.instantiate()
	add_child(popup)
	popup.set_number(amount)
	popup.set_title("HEAL")
	popup.set_color(Color(0.349, 0.767, 0.349, 1.0))
	popup.title_visible()
	var p : Vector2 = target.ui_element.marker_2d.get_global_transform_with_canvas().origin.round()
	popup.snap_center_to_canvas_point(p)
	popup.show_text()

func pop_text_poison(target : Battler, amount : int) -> void:
	var popup : TextPopup = TEXTPOPUP.instantiate()
	add_child(popup)
	popup.set_number(amount)
	popup.set_title("POISON")
	popup.set_color(Color(0.424, 0.0, 0.537, 1.0))
	popup.title_visible()
	var point : Vector2 = target.ui_element.marker_2d.get_global_transform_with_canvas().origin.round()
	popup.snap_center_to_canvas_point(point)
	popup.show_text()
