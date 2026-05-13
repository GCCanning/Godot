extends Node

class_name QuestSystem

var active_quests: Dictionary = {}
var completed_quests: Array[String] = []
var quest_database: Dictionary = {}

signal quest_started(quest_id: String)
signal quest_updated(quest_id: String)
signal quest_completed(quest_id: String, reward: Dictionary)

func _ready():
	setup_quests()

func setup_quests():
	# Starter Town Quests
	add_quest("gather_wood", "Gather Wood", "Collect 10 wood from trees", 1, {"wood": 10}, {"experience": 50, "gold": 25})
	add_quest("hunt_slimes", "Hunt Slimes", "Defeat 5 slimes", 1, {"slimes_defeated": 5}, {"experience": 100, "gold": 50})
	add_quest("explore_forest", "Explore Forest", "Discover the forest zone", 2, {"zones_discovered": 1}, {"experience": 150, "gold": 100})
	add_quest("first_kill", "First Blood", "Defeat your first enemy", 1, {"enemies_defeated": 1}, {"experience": 75, "gold": 35})

func add_quest(quest_id: String, title: String, description: String, rank: int, objectives: Dictionary, rewards: Dictionary):
	quest_database[quest_id] = {
		"id": quest_id,
		"title": title,
		"description": description,
		"rank": rank,
		"objectives": objectives,
		"progress": {},
		"rewards": rewards
	}

func start_quest(quest_id: String, player: Player) -> bool:
	if quest_id not in quest_database:
		return false
	
	if quest_id in active_quests:
		return false
	
	if quest_id in completed_quests:
		return false
	
	var quest = quest_database[quest_id].duplicate(true)
	active_quests[quest_id] = quest
	quest_started.emit(quest_id)
	return true

func update_quest_progress(quest_id: String, objective: String, progress: int):
	if quest_id not in active_quests:
		return
	
	var quest = active_quests[quest_id]
	if objective not in quest["objectives"]:
		return
	
	if not objective in quest["progress"]:
		quest["progress"][objective] = 0
	
	quest["progress"][objective] = progress
	quest_updated.emit(quest_id)
	
	# Check if quest is complete
	check_quest_completion(quest_id)

func check_quest_completion(quest_id: String):
	var quest = active_quests[quest_id]
	var complete = true
	
	for objective in quest["objectives"]:
		var required = quest["objectives"][objective]
		var current = quest["progress"].get(objective, 0)
		
		if current < required:
			complete = false
			break
	
	if complete:
		complete_quest(quest_id)

func complete_quest(quest_id: String):
	var quest = active_quests[quest_id]
	active_quests.erase(quest_id)
	completed_quests.append(quest_id)
	
	quest_completed.emit(quest_id, quest["rewards"])
	print("Quest completed: ", quest["title"])

func get_active_quests() -> Array:
	var quests = []
	for quest_id in active_quests:
		quests.append(active_quests[quest_id])
	return quests

func get_available_quests(player_rank: int) -> Array:
	var quests = []
	for quest_id in quest_database:
		var quest = quest_database[quest_id]
		if quest["rank"] <= player_rank and quest_id not in active_quests and quest_id not in completed_quests:
			quests.append(quest)
	return quests
