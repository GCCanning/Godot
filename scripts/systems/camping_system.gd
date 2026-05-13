extends Node

class_name CampingSystem

var is_camping: bool = false
var camp_duration: float = 3600.0  # 1 hour in-game
var camp_restore_rate: float = 1.0  # Health/Mana/Stamina restore per second

signal camp_started
signal camp_ended
signal camp_interrupted

func start_camp(player: Player) -> bool:
	# Check if player has camping equipment
	if player.inventory.get_item_count("camping_equipment") <= 0:
		print("Need camping equipment to camp")
		return false
	
	is_camping = true
	camp_started.emit()
	
	# Start camping timer
	await get_tree().create_timer(camp_duration / 30.0).timeout  # Simulate for testing
	
	if is_camping:
		end_camp(player)
	
	return true

func end_camp(player: Player):
	if not is_camping:
		return
	
	# Restore player stats
	player.health = player.max_health
	player.mana = player.max_mana
	player.stamina = player.max_stamina
	
	is_camping = false
	camp_ended.emit()
	print("Camp ended. Stats restored.")

func interrupt_camp():
	if is_camping:
		is_camping = false
		camp_interrupted.emit()
		print("Camp interrupted!")

func restore_player_stats(player: Player, delta: float):
	if not is_camping:
		return
	
	var restore_amount = camp_restore_rate * 10 * delta  # 10x faster restoration
	
	if player.health < player.max_health:
		player.health = min(player.max_health, player.health + restore_amount)
	
	if player.mana < player.max_mana:
		player.mana = min(player.max_mana, player.mana + restore_amount)
	
	if player.stamina < player.max_stamina:
		player.stamina = min(player.max_stamina, player.stamina + restore_amount)
