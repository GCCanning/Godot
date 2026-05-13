extends Node

class_name CharacterStats

# Core stats that affect gameplay
var strength: float = 10.0      # Melee damage, carrying capacity
var dexterity: float = 10.0     # Dodge, critical chance, ranged damage
var constitution: float = 10.0  # Health, stamina
var intelligence: float = 10.0  # Mana, spell damage
var wisdom: float = 10.0        # Mana regeneration, perception
var charisma: float = 10.0      # NPC interaction, trading

# Derived stats
var armor: float = 0.0
var magic_resistance: float = 0.0
var critical_chance: float = 0.0
var dodge_chance: float = 0.0

func _ready():
	calculate_derived_stats()

func calculate_derived_stats():
	armor = strength * 0.5
	magic_resistance = intelligence * 0.3
	critical_chance = dexterity * 0.02
	dodge_chance = dexterity * 0.01

func get_stat(stat_name: String) -> float:
	match stat_name:
		"strength":
			return strength
		"dexterity":
			return dexterity
		"constitution":
			return constitution
		"intelligence":
			return intelligence
		"wisdom":
			return wisdom
		"charisma":
			return charisma
		_:
			return 0.0

func apply_buff(stat_name: String, amount: float, duration: float):
	# Implement buff system with duration
	pass
