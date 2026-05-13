extends Node2D

class_name Enemy

@export var health: float = 20.0
@export var max_health: float = 20.0
@export var damage: float = 5.0
@export var speed: float = 100.0
@export var detection_range: float = 150.0
@export var attack_range: float = 30.0

var level: int = 1
var experience_reward: float = 10.0
var enemy_name: String = "Enemy"
var is_alive: bool = true

var player: Node2D
var state: String = "idle"  # idle, chasing, attacking
var attack_cooldown: float = 0.0

signal enemy_died

func _ready():
	player = get_tree().root.get_child(0).find_child("Player")
	experience_reward = level * 10.0

func _physics_process(delta: float):
	if not is_alive:
		return
	
	if not player:
		return
	
	var distance_to_player = global_position.distance_to(player.global_position)
	
	# State machine
	if distance_to_player < detection_range:
		if distance_to_player < attack_range:
			state = "attacking"
			attack_player(delta)
		else:
			state = "chasing"
			chase_player()
	else:
		state = "idle"
		position += Vector2.ZERO  # Can add idle animation

func chase_player():
	var direction = (player.global_position - global_position).normalized()
	global_position += direction * speed * get_physics_process_delta_time()

func attack_player(delta: float):
	attack_cooldown -= delta
	
	if attack_cooldown <= 0:
		if player:
			var damage_amount = damage + randf_range(-2, 2)
			player.take_damage(damage_amount, "melee")
			attack_cooldown = 1.0  # 1 second between attacks

func take_damage(damage_amount: float):
	health -= damage_amount
	
	if health <= 0:
		die()

func die():
	is_alive = false
	enemy_died.emit()
	
	# Drop loot
	if player:
		player.gain_experience(experience_reward)
		# Loot drop would be handled by zone
	
	queue_free()

func get_level_scaling_modifier() -> float:
	# Scale stats based on level
	return 1.0 + (level - 1) * 0.1
