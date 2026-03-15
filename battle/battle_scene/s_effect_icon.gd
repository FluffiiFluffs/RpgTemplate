class_name SEffectIcon
extends TextureRect
## In-battle icon to show status effects on a battlestats for the party members

## Visual representation of the status effect

## This scene should be instantiated in battle
## setup should involve:
	## copying the status_id from the status applied to the statusid variable in this script
	## setting the texture to the correct icon for the status effect
		## This does not include defended or defending
	## Setting the modulate color of this scene depending on the tier applied
## Adding the scene as a child under s_effect_h_box
## If a higher tier is applied, color is replaced by the appropriate level
## If the status effect expires, the scene is free'd
	## This is done by matching the ID of the status expiring to the ID in the icon's scene

@export var statusid : StringName = &""

var status_effect : StatusEffect = null

#region Colors

# Rules for colors:
# If a status effect has a single level, then it is automatically set to level 3
# If a status effect is multiple tiers, then it starts at level 1
# NEG = negative status effects / ailments, POS = positive status effects / buffs
# Maybe needs to be expanded later for higher levels above 3

const LEVELNEG3 = Color(0.735, 0.0, 0.0, 1.0)
const LEVELNEG2 = Color(0.735, 0.248, 0.248, 1.0)
const LEVELNEG1 = Color(0.735, 0.665, 0.424, 1.0)
const LEVELPOS1 = Color(0.665, 0.735, 0.665, 1.0)
const LEVELPOS2 = Color(0.424, 0.735, 0.424, 1.0)
const LEVELPOS3 = Color(0.0, 0.735, 0.0, 1.0)
const WHITE = Color(1.0, 1.0, 1.0, 1.0)

#endregion Colors

# maybe need to just use the UID strings with load instead of preload for memory reasons. use match
const ATKDOWN_18 = preload("uid://bapxa4bckscvo")
const ATKUP_18 = preload("uid://d0e82dapxsbva")
const CONFUSE_18 = preload("uid://bpiv81xtxo8my")
const DEFENSEDOWN_18 = preload("uid://5856hljtq636")
const DEFENSEUP_18 = preload("uid://b1gut0q088e8p")
const HASTE_18 = preload("uid://bh30vkc1rd11x")
const MAGICDOWN_18 = preload("uid://dm1wbn5vssa3l")
const MAGICUP_18 = preload("uid://brvxcsyum15d3")
const POISON_18 = preload("uid://datbagxrt6803")
const SLEEP_18 = preload("uid://ca1ar8vhgs2ti")
const SLOW_18 = preload("uid://cbeoc6vi6idfh")
const STUN_18 = preload("uid://cbkkwqd5prnln")


func setup_from_status(status : StatusEffect) -> void:
	status_effect = status

	if status_effect == null:
		statusid = &""
		texture = null
		self_modulate = WHITE
		return

	statusid = status_effect.status_id
	set_icon_texture()
	set_color()


func set_color()->void:
	if status_effect == null:
		self_modulate = WHITE
		return

	var level : int = _get_visual_level()

	match status_effect.kind:
		StatusEffect.StatusKind.AILMENT:
			match level:
				1:
					self_modulate = LEVELNEG1
				2:
					self_modulate = LEVELNEG2
				_:
					self_modulate = LEVELNEG3

		StatusEffect.StatusKind.ENHANCEMENT:
			match level:
				1:
					self_modulate = LEVELPOS1
				2:
					self_modulate = LEVELPOS2
				_:
					self_modulate = LEVELPOS3

		_:
			self_modulate = WHITE


func set_icon_texture()->void:
	if status_effect == null:
		texture = null
		return

	if status_effect is StatusEffectPoison:
		texture = POISON_18
		return

	match statusid:
		&"statusattackdown":
			texture = ATKDOWN_18
		&"statusattackup":
			texture = ATKUP_18
		&"statusconfuse":
			texture = CONFUSE_18
		&"statusdefensedown":
			texture = DEFENSEDOWN_18
		&"statusdefenseup":
			texture = DEFENSEUP_18
		&"statushaste":
			texture = HASTE_18
		&"statusmagicdown":
			texture = MAGICDOWN_18
		&"statusmagicup":
			texture = MAGICUP_18
		&"statussleep":
			texture = SLEEP_18
		&"statusslow":
			texture = SLOW_18
		&"statusstun":
			texture = STUN_18
		_:
			texture = null


func _get_visual_level() -> int:
	if status_effect is StatusEffectAttackDown:
		return clampi((status_effect as StatusEffectAttackDown).stack_level, 1, 3)

	if status_effect is StatusEffectAttackUp:
		return clampi((status_effect as StatusEffectAttackUp).stack_level, 1, 3)

	if status_effect is StatusEffectDefenseDown:
		return clampi((status_effect as StatusEffectDefenseDown).stack_level, 1, 3)

	if status_effect is StatusEffectDefenseUp:
		return clampi((status_effect as StatusEffectDefenseUp).stack_level, 1, 3)

	if status_effect is StatusEffectMagicDown:
		return clampi((status_effect as StatusEffectMagicDown).stack_level, 1, 3)

	if status_effect is StatusEffectMagicUp:
		return clampi((status_effect as StatusEffectMagicUp).stack_level, 1, 3)

	if status_effect is StatusEffectSlow:
		return clampi((status_effect as StatusEffectSlow).stack_level, 1, 3)

	if status_effect is StatusEffectHaste:
		return clampi((status_effect as StatusEffectHaste).stack_level, 1, 3)

	return 3
