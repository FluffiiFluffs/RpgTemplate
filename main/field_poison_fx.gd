extends CanvasLayer

@onready var poison_rect : ColorRect = %PoisonRect

var _flash_tween : Tween = null
var _base_alpha : float = 0.05
var _flash_alpha : float = 0.20

func _ready() -> void:
	if poison_rect != null:
		_base_alpha = poison_rect.modulate.a

	if CharDataKeeper.poison_field_tick.is_connected(_on_poison_field_tick) == false:
		CharDataKeeper.poison_field_tick.connect(_on_poison_field_tick)

	_refresh_presence()


func _on_poison_field_tick(_member : ActorData, _damage : int) -> void:
	_refresh_presence()
	_flash()


func _refresh_presence() -> void:
	var has_poison : bool = false

	for m in CharDataKeeper.party_members:
		if m == null:
			continue
		if m.current_hp <= 0:
			continue
		if m.status_effects == null:
			continue

		for s in m.status_effects:
			if s is StatusEffectPoison:
				has_poison = true
				break

		if has_poison:
			break

	if poison_rect != null:
		poison_rect.visible = has_poison
		if has_poison:
			var c : Color = poison_rect.modulate
			c.a = _base_alpha
			poison_rect.modulate = c


func _flash() -> void:
	if poison_rect == null:
		return
	if poison_rect.visible == false:
		return

	if _flash_tween != null:
		_flash_tween.kill()
		_flash_tween = null

	_flash_tween = create_tween()

	var c1 : Color = poison_rect.modulate
	c1.a = _flash_alpha
	_flash_tween.tween_property(poison_rect, "modulate", c1, 0.07)

	var c2 : Color = poison_rect.modulate
	c2.a = _base_alpha
	_flash_tween.tween_property(poison_rect, "modulate", c2, 0.10)
