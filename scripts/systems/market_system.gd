extends Node

class_name MarketSystem

var market_prices: Dictionary = {}
var player_gold: float = 100.0

signal gold_changed(amount: float)
signal item_purchased(item: String, price: float)
signal item_sold(item: String, price: float)

func _ready():
	setup_market_prices()

func setup_market_prices():
	# Base prices for items
	market_prices = {
		"wood": 10.0,
		"stone": 15.0,
		"food": 25.0,
		"water": 10.0,
		"health_potion": 50.0,
		"mana_potion": 50.0,
		"stamina_potion": 50.0,
		"camping_equipment": 200.0,
		"rope": 30.0,
		"torch": 20.0,
	}

func buy_item(item_name: String, quantity: int, player: Player) -> bool:
	if item_name not in market_prices:
		return false
	
	var price = market_prices[item_name] * quantity
	
	if player_gold < price:
		print("Not enough gold")
		return false
	
	if player.inventory.add_item(item_name, quantity):
		player_gold -= price
		gold_changed.emit(player_gold)
		item_purchased.emit(item_name, price)
		return true
	
	return false

func sell_item(item_name: String, quantity: int, player: Player) -> bool:
	if item_name not in market_prices:
		return false
	
	if not player.inventory.remove_item(item_name, quantity):
		return false
	
	var price = market_prices[item_name] * quantity * 0.7  # Sell for 70% of buy price
	player_gold += price
	gold_changed.emit(player_gold)
	item_sold.emit(item_name, price)
	return true

func get_item_price(item_name: String) -> float:
	return market_prices.get(item_name, 0.0)

func get_player_gold() -> float:
	return player_gold

func add_gold(amount: float):
	player_gold += amount
	gold_changed.emit(player_gold)
