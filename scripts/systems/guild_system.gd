extends Node

class_name GuildSystem

var player_guild: String = ""
var player_rank: int = 0
var guilds: Dictionary = {}

signal joined_guild(guild_name: String)
signal guild_rank_up(new_rank: int)

func _ready():
	setup_guilds()

func setup_guilds():
	add_guild("Adventurers Guild", "The main hub for adventurers seeking fame and fortune")
	add_guild("Mages Circle", "A society for those who wield arcane magic")
	add_guild("Rogues Shadow", "An underground network for sneaky individuals")
	add_guild("Rangers Lodge", "For those who prefer the wilderness")
	add_guild("Holy Order", "Knights and paladins dedicated to righteousness")

func add_guild(name: String, description: String):
	guilds[name] = {
		"name": name,
		"description": description,
		"ranks": ["Recruit", "Member", "Veteran", "Elite", "Master"],
		"member_count": 0
	}

func join_guild(player: Player, guild_name: String) -> bool:
	if guild_name not in guilds:
		return false
	
	player_guild = guild_name
	player_rank = 0  # Start at recruit
	guilds[guild_name]["member_count"] += 1
	
	joined_guild.emit(guild_name)
	return true

func complete_guild_quest(quests_completed: int):
	# Rank up based on quest completion
	var new_rank = int(quests_completed / 5)
	if new_rank > player_rank and new_rank < guilds[player_guild]["ranks"].size():
		player_rank = new_rank
		guild_rank_up.emit(player_rank)
		print("Guild rank up to: ", guilds[player_guild]["ranks"][player_rank])

func get_guild_rank_name() -> String:
	if player_guild not in guilds:
		return "None"
	return guilds[player_guild]["ranks"][player_rank]

func get_player_guild() -> String:
	return player_guild

func get_player_rank() -> int:
	return player_rank
