extends EditorScript
# This script sets up the entire Godot isometric survival game project structure
# Run this from the Script Editor (File > Run)

var base_path = "res://"
var scripts = {}
var scenes = {}

func _run():
	print("Starting project setup...")
	
	# Create all directories
	create_directories()
	
	# Create all scripts
	create_scripts()
	
	# Create main scene
	create_main_scene()
	
	print("Project setup complete!")
	print("Next steps:")
	print("1. Create a TileSet with tiles (grass, water, forest, mountain)")
	print("2. Add player sprite assets to res://assets/sprites/")
	print("3. Run the main.tscn scene")

func create_directories():
	print("Creating directory structure...")
	var directories = [
		"res://scenes",
		"res://scenes/main",
		"res://scenes/player",
		"res://scenes/terrain",
		"res://scenes/ui",
		"res://scripts",
		"res://scripts/terrain",
		"res://scripts/player",
		"res://scripts/systems",
		"res://scripts/camera",
		"res://assets",
		"res://assets/tiles",
		"res://assets/sprites",
		"res://assets/tilesets",
	]
	
	for dir_path in directories:
		if not DirAccess.dir_exists_absolute(dir_path):
			DirAccess.make_abs_absolute(dir_path)
			print("  Created: " + dir_path)

func create_scripts():
	print("Creating script files...")
	
	# TerrainGenerator script
	var terrain_generator = """extends Node2D

class_name TerrainGenerator

@export var tile_size: int = 32
@export var chunk_size: int = 16
@export var view_distance: int = 3

var noise: FastNoise3D
var loaded_chunks: Dictionary = {}
var player_chunk: Vector2i = Vector2i.ZERO
var tilemap: TileMap
var player: Node2D

func _ready():
	tilemap = get_node("../TileMap")
	player = get_node("../Player")
	
	noise = FastNoise3D.new()
	noise.noise_type = FastNoise3D.NoiseType.NOISE_TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.05

func _process(_delta):
	update_chunks()

func update_chunks():
	var current_chunk = get_chunk_at_position(player.global_position)
	
	if current_chunk != player_chunk:
		player_chunk = current_chunk
		load_visible_chunks()
		unload_far_chunks()

func load_visible_chunks():
	for x in range(-view_distance, view_distance + 1):
		for y in range(-view_distance, view_distance + 1):
			var chunk_pos = player_chunk + Vector2i(x, y)
			if not chunk_pos in loaded_chunks:
				generate_chunk(chunk_pos)

func generate_chunk(chunk_pos: Vector2i):
	var world_x = chunk_pos.x * chunk_size
	var world_y = chunk_pos.y * chunk_size
	
	for local_y in range(chunk_size):
		for local_x in range(chunk_size):
			var world_tile_x = world_x + local_x
			var world_tile_y = world_y + local_y
			
			var noise_val = noise.GetNoise3D(float(world_tile_x), float(world_tile_y), 0.0)
			var tile_type = get_tile_type(noise_val)
			
			tilemap.set_cell(0, Vector2i(world_tile_x, world_tile_y), tile_type, Vector2i(0, 0))
	
	loaded_chunks[chunk_pos] = true

func unload_far_chunks():
	var chunks_to_remove = []
	for chunk_pos in loaded_chunks:
		var distance = chunk_pos.distance_to(player_chunk)
		if distance > view_distance + 1:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		loaded_chunks.erase(chunk_pos)

func get_tile_type(noise_value: float) -> int:
	if noise_value < -0.3:
		return 0  # Water
	elif noise_value < 0.2:
		return 1  # Grass
	elif noise_value < 0.5:
		return 2  # Forest
	else:
		return 3  # Mountain

func get_chunk_at_position(pos: Vector2) -> Vector2i:
	var chunk_pixel_size = tile_size * chunk_size
	return Vector2i(int(pos.x / chunk_pixel_size), int(pos.y / chunk_pixel_size))
"""
	
	create_file("res://scripts/terrain/terrain_generator.gd", terrain_generator)
	
	# Player script
	var player_script = """extends CharacterBody2D

class_name Player

@export var speed: float = 200.0
var animation_player: AnimationPlayer

func _ready():
	if has_node("AnimationPlayer"):
		animation_player = $AnimationPlayer

func _physics_process(delta: float):
	var input_vector = Vector2.ZERO
	
	input_vector.x = Input.get_axis("ui_left", "ui_right")
	input_vector.y = Input.get_axis("ui_up", "ui_down")
	
	if input_vector != Vector2.ZERO:
		velocity = input_vector.normalized() * speed
		if animation_player:
			animation_player.play("walk")
	else:
		velocity = Vector2.ZERO
		if animation_player:
			animation_player.play("idle")
	
	move_and_slide()
"""
	
	create_file("res://scripts/player/player.gd", player_script)
	
	# Inventory script
	var inventory_script = """extends Node

class_name Inventory

var items: Dictionary = {}
var max_slots: int = 20

signal inventory_changed

func _ready():
	items = {
		"wood": 0,
		"stone": 0,
		"food": 0,
		"water": 0
	}

func add_item(item_type: String, amount: int = 1) -> bool:
	if item_type in items:
		items[item_type] += amount
		inventory_changed.emit()
		return true
	return false

func remove_item(item_type: String, amount: int = 1) -> bool:
	if item_type in items and items[item_type] >= amount:
		items[item_type] -= amount
		inventory_changed.emit()
		return true
	return false

func get_item_count(item_type: String) -> int:
	return items.get(item_type, 0)
"""
	
	create_file("res://scripts/player/inventory.gd", inventory_script)
	
	# IsometricCamera script
	var camera_script = """extends Camera2D

class_name IsometricCamera

@export var zoom_speed: float = 0.1
@export var min_zoom: float = 0.5
@export var max_zoom: float = 3.0

var target_zoom: float = 1.0
var player: Node2D

func _ready():
	player = get_parent().find_child("Player")
	target_zoom = zoom.x

func _process(delta: float):
	if player:
		global_position = player.global_position
	
	zoom = zoom.lerp(Vector2.ONE * target_zoom, delta * 5.0)

func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			target_zoom = clamp(target_zoom + zoom_speed, min_zoom, max_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			target_zoom = clamp(target_zoom - zoom_speed, min_zoom, max_zoom)
"""
	
	create_file("res://scripts/camera/isometric_camera.gd", camera_script)
	
	# TileInteraction script
	var interaction_script = """extends Node2D

class_name TileInteraction

var player: Player
var tilemap: TileMap
var interaction_range: float = 50.0

enum ResourceType { TREE, ROCK, BUSH, WATER }

func _ready():
	player = get_parent().find_child("Player")
	tilemap = get_parent().find_child("TileMap")

func _input(event: InputEvent):
	if event.is_action_pressed("interact"):
		handle_interaction()

func handle_interaction():
	var nearby_resources = find_nearby_resources()
	
	for resource in nearby_resources:
		if player.global_position.distance_to(resource.global_position) <= interaction_range:
			interact_with_resource(resource)

func find_nearby_resources() -> Array:
	var nearby = []
	var pos = player.global_position
	
	for node in get_tree().get_nodes_in_group("resources"):
		if node.global_position.distance_to(pos) <= interaction_range:
			nearby.append(node)
	
	return nearby

func interact_with_resource(resource: Node2D):
	if resource.is_in_group("trees"):
		harvest_tree(resource)
	elif resource.is_in_group("rocks"):
		harvest_rock(resource)

func harvest_tree(tree: Node2D):
	print("Harvested wood")
	tree.queue_free()

func harvest_rock(rock: Node2D):
	print("Harvested stone")
	rock.queue_free()
"""
	
	create_file("res://scripts/systems/tile_interaction.gd", interaction_script)
	
	# DayNightCycle script
	var day_night_script = """extends CanvasLayer

class_name DayNightCycle

@export var cycle_duration: float = 120.0
@export var day_color: Color = Color.WHITE
@export var night_color: Color = Color.DARK_SLATE_GRAY

var time_elapsed: float = 0.0
var color_rect: ColorRect

func _ready():
	color_rect = ColorRect.new()
	color_rect.anchor_right = 1.0
	color_rect.anchor_bottom = 1.0
	color_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(color_rect)

func _process(delta: float):
	time_elapsed += delta
	if time_elapsed > cycle_duration:
		time_elapsed = 0.0
	
	var cycle_progress = time_elapsed / cycle_duration
	var current_color = day_color.lerp(night_color, sin(cycle_progress * PI))
	
	color_rect.color = current_color

func get_time_of_day() -> float:
	return (time_elapsed / cycle_duration) * 24.0
"""
	
	create_file("res://scripts/systems/day_night_cycle.gd", day_night_script)

func create_file(path: String, content: String):
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		file.store_string(content)
		print("  Created: " + path)
	else:
		print("  ERROR creating: " + path)

func create_main_scene():
	print("Creating main scene...")
	
	var main_scene = PackedScene.new()
	
	# Create Main node
	var main_node = Node2D.new()
	main_node.name = "Main"
	main_scene.pack(main_node)
	
	# Create TileMap
	var tilemap = TileMap.new()
	tilemap.name = "TileMap"
	main_node.add_child(tilemap)
	
	# Create Player
	var player = CharacterBody2D.new()
	player.name = "Player"
	player.position = Vector2(0, 0)
	main_node.add_child(player)
	
	# Add CollisionShape2D to player
	var collision = CollisionShape2D.new()
	var capsule = CapsuleShape2D.new()
	capsule.radius = 8
	capsule.height = 20
	collision.shape = capsule
	player.add_child(collision)
	
	# Add Sprite2D to player
	var sprite = Sprite2D.new()
	sprite.name = "Sprite2D"
	player.add_child(sprite)
	
	# Add AnimationPlayer to player
	var anim_player = AnimationPlayer.new()
	anim_player.name = "AnimationPlayer"
	player.add_child(anim_player)
	
	# Create Camera2D
	var camera = Camera2D.new()
	camera.name = "Camera2D"
	main_node.add_child(camera)
	
	# Create UI CanvasLayer
	var ui = CanvasLayer.new()
	ui.name = "UI"
	main_node.add_child(ui)
	
	# Create Systems node
	var systems = Node.new()
	systems.name = "Systems"
	main_node.add_child(systems)
	
	# Add TerrainGenerator
	var terrain_gen = Node2D.new()
	terrain_gen.name = "TerrainGenerator"
	var terrain_script = load("res://scripts/terrain/terrain_generator.gd")
	terrain_gen.set_script(terrain_script)
	systems.add_child(terrain_gen)
	
	# Add TileInteraction
	var tile_interaction = Node2D.new()
	tile_interaction.name = "TileInteraction"
	var interaction_script = load("res://scripts/systems/tile_interaction.gd")
	tile_interaction.set_script(interaction_script)
	systems.add_child(tile_interaction)
	
	# Add DayNightCycle
	var day_night = CanvasLayer.new()
	day_night.name = "DayNightCycle"
	var day_night_script = load("res://scripts/systems/day_night_cycle.gd")
	day_night.set_script(day_night_script)
	systems.add_child(day_night)
	
	# Attach scripts to nodes
	var player_script = load("res://scripts/player/player.gd")
	player.set_script(player_script)
	
	var camera_script = load("res://scripts/camera/isometric_camera.gd")
	camera.set_script(camera_script)
	
	# Save the scene
	ResourceSaver.save(main_scene, "res://scenes/main/main.tscn")
	print("  Created: res://scenes/main/main.tscn")
