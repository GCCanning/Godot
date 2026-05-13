extends Node

class_name Inventory

var items: Dictionary = {}
var max_slots: int = 30
var current_weight: float = 0.0
var max_weight: float = 100.0

signal inventory_changed
signal inventory_full

func _ready():
	items = {
		"wood": {"count": 0, "weight": 0.5},
		"stone": {"count": 0, "weight": 1.0},
		"food": {"count": 0, "weight": 0.2},
		"water": {"count": 0, "weight": 0.5},
		"health_potion": {"count": 0, "weight": 0.3},
		"mana_potion": {"count": 0, "weight": 0.3},
		"stamina_potion": {"count": 0, "weight": 0.3},
		"camping_equipment": {"count": 0, "weight": 5.0},
		"rope": {"count": 0, "weight": 1.0},
		"torch": {"count": 0, "weight": 0.5},
	}

func add_item(item_type: String, amount: int = 1) -> bool:
	if item_type not in items:
		print("Item type not found: ", item_type)
		return false
	
	var item_weight = items[item_type]["weight"] * amount
	
	if current_weight + item_weight > max_weight:
		inventory_full.emit()
		return false
	
	items[item_type]["count"] += amount
	current_weight += item_weight
	inventory_changed.emit()
	return true

func remove_item(item_type: String, amount: int = 1) -> bool:
	if item_type not in items or items[item_type]["count"] < amount:
		return false
	
	items[item_type]["count"] -= amount
	current_weight -= items[item_type]["weight"] * amount
	inventory_changed.emit()
	return true

func get_item_count(item_type: String) -> int:
	return items.get(item_type, {}).get("count", 0)

func get_inventory_percentage() -> float:
	return current_weight / max_weight

func is_full() -> bool:
	return current_weight >= max_weight
