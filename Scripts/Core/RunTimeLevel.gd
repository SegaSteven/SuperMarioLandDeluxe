extends Node

@onready var level_name = name

var max_score = 0
var max_coins = 0

func _ready():
	GameManager.level_beaten.connect(beat_level)
	set_values()

func set_values():
	for node in get_children():
		if node is CollectableCoin:
			max_score += node.score
			max_coins += node.coins
		if node is Enemy:
			max_score += node.score

func beat_level():
	LevelData.generate_level(LevelData.level_dic[level_name]["unlocks"])
	LevelData.level_dic[LevelData.level_dic["unlocks"]]["unlocked"] = true

	LevelData.update_level(level_name, LevelData.score, max_score, LevelData.coins, max_coins, true)
