extends Node2D

class_name Zone

@export var zone_id: int = 0
@export var zone_name: String = "Default Zone"
@export var zone_level: int = 1
@export var zone_level_range: Vector2i = Vector2i(1, 5)  # Min and max level mobs
@export var biome_type: String = "forest"  # forest, desert, ice, volcanic, etc.
@export var tile_size: int = 32
@export var chunk_size: int = 16
@export var view_distance: int = 3

var tilemap: TileMap
var noise: FastNoise3D
var loaded_chunks: Dictionary = {}
var current_chunk: Vector2i = Vector2i.ZERO
var spawned_mobs: Array[Node2D] = []
var zone_loot_table: Dictionary = {}

signal mob_spawned(mob: Enemy)
signal player_entered_zone(zone: Zone)

func _ready():
	tilemap = get_node_or_null("TileMap")
	
	noise = FastNoise3D.new()
	noise.noise_type = FastNoise3D.NoiseType.NOISE_TYPE_PERLIN
	noise.seed = randi()
	noise.frequency = 0.05
	
	setup_loot_table()
	print("Zone initialized: ", zone_name, " (Level ", zone_level, ")")

func _process(delta: float):
	update_chunks()
	update_mob_spawning()

func update_chunks():
	if not tilemap:
		return
	
	var player = get_tree().root.get_child(0).find_child("Player")
	if not player:
		return
	
	var new_chunk = get_chunk_at_position(player.global_position)
	
	if new_chunk != current_chunk:
		current_chunk = new_chunk
		load_visible_chunks()
		unload_far_chunks()

func load_visible_chunks():
	for x in range(-view_distance, view_distance + 1):
		for y in range(-view_distance, view_distance + 1):
			var chunk_pos = current_chunk + Vector2i(x, y)
			if chunk_pos not in loaded_chunks:
				generate_chunk(chunk_pos)

func generate_chunk(chunk_pos: Vector2i):
	var world_x = chunk_pos.x * chunk_size
	var world_y = chunk_pos.y * chunk_size
	
	for local_y in range(chunk_size):
		for local_x in range(chunk_size):
			var world_tile_x = world_x + local_x
			var world_tile_y = world_y + local_y
			
			var noise_val = noise.GetNoise3D(float(world_tile_x), float(world_tile_y), 0.0)
			var tile_type = get_tile_for_biome(noise_val, biome_type)
			
			if tilemap:
				tilemap.set_cell(0, Vector2i(world_tile_x, world_tile_y), tile_type, Vector2i(0, 0))
	
	loaded_chunks[chunk_pos] = true

func unload_far_chunks():
	var chunks_to_remove = []
	for chunk_pos in loaded_chunks:
		var distance = chunk_pos.distance_to(current_chunk)
		if distance > view_distance + 1:
			chunks_to_remove.append(chunk_pos)
	
	for chunk_pos in chunks_to_remove:
		loaded_chunks.erase(chunk_pos)

func get_tile_for_biome(noise_value: float, biome: String) -> int:
	match biome:
		"forest":
			if noise_value < -0.3:
				return 0  # Water
			elif noise_value < 0.2:
				return 1  # Grass
			elif noise_value < 0.5:
				return 2  # Forest
			else:
				return 3  # Mountain
		"desert":
			if noise_value < -0.2:
				return 0  # Water
			elif noise_value < 0.6:
				return 4  # Sand
			else:
				return 5  # Rocky desert
		"ice":
			if noise_value < 0.0:
				return 6  # Ice
			else:
				return 7  # Snow
		_:
			return 1

func get_chunk_at_position(pos: Vector2) -> Vector2i:
	var chunk_pixel_size = tile_size * chunk_size
	return Vector2i(int(pos.x / chunk_pixel_size), int(pos.y / chunk_pixel_size))

func update_mob_spawning():
	# Spawn mobs based on proximity to player
	var player = get_tree().root.get_child(0).find_child("Player")
	if not player:
		return
	
	# Limit spawned mobs
	if spawned_mobs.size() > 20:
		return
	
	if randf() < 0.01:  # 1% chance per frame to spawn
		spawn_random_mob(player.global_position)

func spawn_random_mob(player_pos: Vector2):
	# Spawn mob near player
	var offset = Vector2(randf_range(-200, 200), randf_range(-200, 200))
	var mob_pos = player_pos + offset
	
	var mob_level = randi_range(zone_level_range.x, zone_level_range.y)
	var enemy = Enemy.new()
	enemy.global_position = mob_pos
	enemy.level = mob_level
	
	add_child(enemy)
	spawned_mobs.append(enemy)
	mob_spawned.emit(enemy)

func setup_loot_table():
	# Define loot drops for this zone
	zone_loot_table = {
		"common": ["wood", "stone"],
		"uncommon": ["health_potion", "mana_potion"],
		"rare": ["rare_ore", "rare_gem"]
	}

func get_zone_loot() -> String:
	var rarity = ["common", "common", "common", "uncommon", "rare"]
	var selected_rarity = rarity[randi() % rarity.size()]
	var loot_list = zone_loot_table.get(selected_rarity, [])
	return loot_list[randi() % loot_list.size()] if loot_list else "wood"
