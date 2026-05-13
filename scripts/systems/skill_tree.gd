extends Node

class_name SkillTree

var skills: Dictionary = {}
var learned_skills: Array[String] = []

signal skill_learned(skill_name: String)

func _ready():
	setup_skill_trees()

func setup_skill_trees():
	# Warrior skills
	add_skill("slash", "warrior", 1, 20.0, 0.0, "Deal 120% weapon damage")
	add_skill("shield_bash", "warrior", 3, 40.0, 0.0, "Stun enemy for 1s, 150% damage")
	add_skill("whirlwind", "warrior", 5, 60.0, 0.0, "Attack all nearby enemies")
	
	# Mage skills
	add_skill("fireball", "mage", 1, 30.0, 20.0, "Deal 180% intelligence damage")
	add_skill("ice_storm", "mage", 3, 50.0, 40.0, "Freeze enemies for 2s")
	add_skill("teleport", "mage", 5, 70.0, 30.0, "Instantly move 100 units")
	
	# Rogue skills
	add_skill("backstab", "rogue", 1, 25.0, 0.0, "Deal 200% damage from behind")
	add_skill("shadow_clone", "rogue", 3, 45.0, 25.0, "Create decoy for 5s")
	add_skill("smoke_bomb", "rogue", 5, 55.0, 30.0, "Escape and become invisible 3s")
	
	# Ranger skills
	add_skill("power_shot", "ranger", 1, 30.0, 0.0, "Deal 150% ranged damage")
	add_skill("multishot", "ranger", 3, 50.0, 20.0, "Shoot 3 arrows")
	add_skill("tracking", "ranger", 5, 40.0, 15.0, "Mark enemy, +50% damage vs marked")
	
	# General skills (available to all)
	add_skill("sprint", "general", 1, 0.0, 0.0, "Increase speed 50% for 5s")
	add_skill("dodge_roll", "general", 1, 0.0, 0.0, "Quick dodge with i-frames")
	add_skill("basic_attack", "general", 1, 10.0, 0.0, "Standard attack")

func add_skill(skill_name: String, class_type: String, level_req: int, mana_cost: float, stamina_cost: float, description: String):
	skills[skill_name] = {
		"name": skill_name,
		"class": class_type,
		"level_required": level_req,
		"mana_cost": mana_cost,
		"stamina_cost": stamina_cost,
		"description": description,
		"cooldown": 0.0
	}

func learn_skill(skill_name: String, player: Player) -> bool:
	if skill_name not in skills:
		return false
	
	if skill_name in learned_skills:
		return false
	
	var skill = skills[skill_name]
	
	# Check requirements
	if skill["level_required"] > player.level:
		print("Player level too low for skill: ", skill_name)
		return false
	
	if skill["class"] != "general" and skill["class"] != player.current_class:
		print("Wrong class for skill: ", skill_name)
		return false
	
	learned_skills.append(skill_name)
	skill_learned.emit(skill_name)
	return true

func cast_skill(skill_name: String, player: Player, target: Node2D = null) -> bool:
	if skill_name not in learned_skills:
		print("Skill not learned: ", skill_name)
		return false
	
	var skill = skills[skill_name]
	
	# Check resources
	if not player.consume_mana(skill["mana_cost"]):
		print("Not enough mana for: ", skill_name)
		return false
	
	if not player.consume_stamina(skill["stamina_cost"]):
		print("Not enough stamina for: ", skill_name)
		return false
	
	# Execute skill
	execute_skill(skill_name, player, target)
	return true

func execute_skill(skill_name: String, player: Player, target: Node2D = null):
	match skill_name:
		"slash":
			if target:
				target.take_damage(player.stats.strength * 1.2)
		"fireball":
			if target:
				target.take_damage(player.stats.intelligence * 1.8)
		"backstab":
			if target:
				target.take_damage(player.stats.dexterity * 2.0)
		"sprint":
			player.speed *= 1.5
		# Add more skill implementations
	
	print("Skill cast: ", skill_name)

func get_learned_skills() -> Array[String]:
	return learned_skills

func get_available_skills(player: Player) -> Array[String]:
	var available = []
	for skill_name in skills:
		var skill = skills[skill_name]
		if skill["level_required"] <= player.level:
			if skill["class"] == "general" or skill["class"] == player.current_class:
				if skill_name not in learned_skills:
					available.append(skill_name)
	return available
