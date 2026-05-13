extends Node

class_name GameManager

# Singleton for managing global game state
static var instance: GameManager

var player: Player
var current_zone: Zone
var world_time: float = 0.0  # In-game time
var game_started: bool = false

signal zone_changed(new_zone: Zone)
signal class_assigned(class_type: String)
signal player_died

func _ready():
	if instance == null:
		instance = self
	else:
		queue_free()
	
	set_multiplayer_authority(str(get_multiplayer_authority()).to_int())

func _process(delta: float):
	if game_started:
		world_time += delta
		check_class_assignment()

func check_class_assignment():
	# At 7 in-game days, assign a class based on player actions
	var days_passed = world_time / 86400.0  # Assuming 86400 seconds per day
	if days_passed >= 7.0 and not player.has_class:
		assign_class_to_player()

func assign_class_to_player():
	var class_type = player.calculate_class_affinity()
	player.assign_class(class_type)
	class_assigned.emit(class_type)
	print("Player assigned class: ", class_type)

func change_zone(zone: Zone):
	current_zone = zone
	zone_changed.emit(zone)

func get_world_time() -> float:
	return world_time

func get_time_of_day() -> int:
	# Returns hour of day (0-23)
	return int((world_time / 3600.0) % 24)
