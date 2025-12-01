class_name Item
extends Resource

enum EquipClass {
	NONE = 0,
	WARRIOR = 1,
	THIEF = 2,
	MAGE = 4,
	HEALER = 8,
	ENEMY = 16,
	BOSS = 32,
}

enum ItemType { UNIQUE, TOOL, HEAL, STATUSHEAL, WEAPON, OFFHAND, HEAD, CHEST, ARMS, LEGS, ACCESSORY }


enum BattleUse {CANNOT, CAN, ONLY}
enum FieldTargeting { ONE, ALL }
enum BattleTargeting { ONE, PARTY, ALL }



##Unique ID of the item
@export var item_id : StringName = ""
##Name of the item
@export var name : String = ""
##Highest quantity to hold in a stack
@export_range(1, 999) var max_stack_size : int = 99
##If more than one stack can be made of this item
@export var unique : bool = false
##Type of the item[br]
##Key=0, Tool=1, Heal=2, Statusheal=3, Weapon=4, Head=5, Chest=6, Arms=7, Legs=8, Accessory=9
@export_enum("UNIQUE", "TOOL", "HEAL", "STATUSHEAL", "WEAPON", "OFFHAND", "HEAD", "CHEST", "ARMS", "LEGS", "ACCESSORY")
var type: int = ItemType.UNIQUE
##Sprite used for the item in the description
@export var menu_sprite : Texture2D = null
##Sprite used for the menu (next to the item)
@export var menu_icon : Texture2D = null
##Sprite on the field
@export var field_sprite : Texture2D = null
@export_multiline var description : String = ""
##Effects that happen when item is used
@export var effects : Array[ItemEffect] = []
##Effects that happen when the item is used in battle
@export var battle_effects : Array[ItemEffect] = []
##Item quantity decreases when used
@export var one_less_on_use : bool = true
##If the item can be used in battle, or only in battle[br]cannot = 0, can = 1, only = 2
@export_enum("Cannot", "Can", "Only") var battle_use : int = BattleUse.CANNOT
##If the item targets one member of the party or all when used in field menu
@export var field_targeting : FieldTargeting = FieldTargeting.ONE
##Who the item's effects target during battle
@export var battle_targeting : BattleTargeting = BattleTargeting.ONE


##Shop values
@export_category("Shop")
##If the item can be sold
@export var can_be_sold : bool = true
##Value used to set price in shop
@export var buy_price : int = 0
##Value used when attempting to sell item
@export var sell_price : int = 0

##Only applicable for equipment
@export_category("Equip")
##Who can equip the item
@export_flags( "Warrior", "Thief" ,"Mage", "Healer", "Enemy", "Boss" ) var can_equip: int = EquipClass.NONE
##Effects that activate when equipped
@export var equip_effect : Array[EquipEffect] = []
##Adds to character's max_hp when equipped
@export var hp_bonus : int = 0 
##Adds to character's max_mp when equipped
@export var mp_bonus : int = 0
##Adds to character's atk_value when equipped
@export var atk_bonus : int = 0
##Adds to character's def_value when equipped
@export var def_bonus : int = 0
##Adds to character's strength when equipped
@export var strength_bonus : int = 0
##Adds to character's stamina when equipped
@export var stamina_bonus : int = 0
##Adds to character's speed when equipped
@export var speed_bonus : int = 0
##Adds to character's magic when equipped
@export var magic_bonus : int = 0
