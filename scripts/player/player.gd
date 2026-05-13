extends CharacterBody2D

class_name Player

@export var speed: float = 150.0
@export var health: float = 100.0
@export var max_health: float = 100.0
@export var mana: float = 50.0
@export var max_mana: float = 50.0
@export var stamina: float = 100.0
@export var max_stamina: float = 100.0

var player_name: String = ""
var level: int = 1
var experience: float = 0.0
var has_class: bool = false
var current_class: String = ""

# Action tracking for class assignment
var action_points: Dictionary = {
	"warrior": 0.0,
	"mage": 0.0,
	"rogue": 0.0,
	"ranger": 0.0,
	"paladin": 0.0
}

var inventory: Inventory
var stats: CharacterStats
var animation_player: AnimationPlayer
var current_zone: Zone

signal health_changed(new_health: float)
signal mana_changed(new_mana: float)
signal stamina_changed(new_stamina: float)
signal level_up(new_level: int)
signal class_assigned(class_type: String)

func _ready():
	if has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer
	
	inventory = Inventory.new()
	add_child(inventory)
	
	stats = CharacterStats.new()
	add_child(stats)

func _physics_process(delta: float):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * speed
		update_animation(input_vector)
		consume_stamina(delta * 10.0)  # Movement costs stamina
	else:
		velocity = Vector2.ZERO
		if animation_player:
			animation_player.play("idle")
		regenerate_stamina(delta * 5.0)  # Stamina regenerates when idle
	
	move_and_slide()

func update_animation(direction: Vector2):
	if not animation_player:
		return
	
	var angle = atan2(direction.y, direction.x)
	var anim_name = "walk"
	
	if angle > -PI/4 and angle <= PI/4:
		anim_name = "walk_right"
	elif angle > PI/4 and angle <= 3*PI/4:
		anim_name = "walk_down"
	elif angle > 3*PI/4 or angle <= -3*PI/4:
		anim_name = "walk_left"
	else:
		anim_name = "walk_up"
	
	if animation_player.current_animation != anim_name:
		animation_player.play(anim_name)

func take_damage(damage: float, damage_type: String = "physical"):
	health = max(0, health - damage)
	health_changed.emit(health)
	
	if health <= 0:
		die()

func heal(amount: float):
	health = min(max_health, health + amount)
	health_changed.emit(health)

func consume_mana(amount: float) -> bool:
	if mana >= amount:
		mana -= amount
		mana_changed.emit(mana)
		return true
	return false

func regenerate_mana(amount: float):
	mana = min(max_mana, mana + amount)
	mana_changed.emit(mana)

func consume_stamina(amount: float) -> bool:
	if stamina >= amount:
		stamina -= amount
		stamina_changed.emit(stamina)
		return true
	return false

func regenerate_stamina(amount: float):
	stamina = min(max_stamina, stamina + amount)
	stamina_changed.emit(stamina)

func gain_experience(amount: float):
	experience += amount
	
	# Simple leveling: 100 XP per level
	var new_level = int(experience / 100.0) + 1
	if new_level > level:
		level = new_level
		level_up.emit(level)
		print("Level up! Now level: ", level)

func track_action(action_type: String):
	# Track player actions for class assignment
	if action_type in action_points:
		action_points[action_type] += 1.0

func calculate_class_affinity() -> String:
	# Determine class based on tracked actions
	var highest_affinity = ""
	var highest_value = 0.0
	
	for class_name in action_points:
		if action_points[class_name] > highest_value:
			highest_value = action_points[class_name]
			highest_affinity = class_name
	
	return highest_affinity if highest_affinity else "warrior"

func assign_class(class_type: String):
	current_class = class_type
	has_class = true
	class_assigned.emit(class_type)
	
	# Apply class-specific stat bonuses
	match class_type:
		"warrior":
			max_health += 30
			stats.strength += 5
		"mage":
			max_mana += 50
			stats.intelligence += 8
		"rogue":
			speed += 50
			stats.dexterity += 8
		"ranger":
			stats.dexterity += 5
			stats.wisdom += 5
		"paladin":
			max_health += 20
			max_mana += 20
			stats.wisdom += 5

func die():
	print("Player died!")
	# Respawn at last checkpoint or town
	global_position = Vector2(0, 0)  # Respawn at origin for now
	health = max_health
	health_changed.emit(health)
