extends Node

signal level_start()

var countdown_value : int = 400
var level_completed = false

var level_dic = {
	"level1" :{
		"unlocked" : true,
		"score" : 0,
		"max_score" : 0,
		"coins" : 0,
		"max_coins" : 0,
		"unlocks" : "level2",
		"beaten" : false
	}
}

func generate_level(level):
	if level not in level_dic:
		level_dic[level] = {
			"unlocked" : false,
			"score" : 0,
			"max_score" : 0,
			"coins" : 0,
			"max_coins" : 0,
			"unlocks" : generate_level_number(level),
			"beaten" : false
		}

func generate_level_number(level):
	var level_number = ""
	for character in level:
		if character.is_valid_int():
			level_number += character
	level_number = int(level_number) + 1
	return "level" + str(level_number)

func update_level(level, score, max_score, coins, max_coins, beaten):
	level_dic[level]["score"] = score
	level_dic[level]["max_score"] = max_score
	level_dic[level]["coins"] = coins
	level_dic[level]["max_coins"] = max_coins
	level_dic[level]["beaten"] = beaten

var score: int = 0
var coins: int = 0
var lives: int = 0

# Coins handling
var coin_queue: int = 0

@export var ui: UI
@export var player: Player
@export var level_music : AudioStreamPlayer
var beaten = false

var music_position = 0
var firsttime_load = false

# OnReady references ----------------------------------------------------------
@onready var PLAYER_SCENE = preload("res://Scenes/player.tscn")
@onready var pause_label = get_node("Pause")

# Coins reach this number a 1up is given
const num_coins_for_1up: int = 100

# maximum number of lives that mario can have. --------------------------------
const max_num_lives: int = 99

# maximum number of coins that mario can collect at once ----------------------
const max_num_coins: int = 100


# Called when the node enters the scene tree for the first time.
#func _ready():

	#player.castle_entered.connect(ui.on_finish)
	
	#if SceneData.points_global != 0:
		#SceneData.points_global = points
		#ui.set_score(points)
	#if SceneData.lives_global != 0:
		#SceneData.lives_global = lives
		#ui.set_lives(lives)
	#if SceneData.coins_global != 0:
		#SceneData.coins_global = coins
		#ui.set_coins(coins)



func save_state():
	GameManager.points_global = score
	GameManager.coins_global = coins
#
func load_state():
	emit_signal("gain_coins", coins)
	emit_signal("gain_points", score)

func fresh_start():
	pass

func win_level():
	emit_signal("level_beaten")
	emit_signal("gain_points" + str(score))

func swap_pause_state():	
	if not pause_label.visible:
		pause_label.show()
		music_position = level_music.get_playback_position()
		level_music.stop()
		Engine.time_scale = 0
		get_tree().paused = true
	else:
		get_tree().paused = false
		level_music.play(music_position)
		Engine.time_scale = 1
		pause_label.hide()
