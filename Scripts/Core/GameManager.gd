extends Node

signal gain_coins(int)
signal gain_life(int)
signal lost_life(int)
signal gain_points(int)
signal level_beaten()
signal level_Start()


var coins : int
var score : int
var lives : int

var superstar = false

var level_finished = false
var current_checkpoint : Checkpoint
var win_screen
var score_label
var music_position = 0

var player : Player

var spawn_point: Vector2
var pre_level: String
@export var player_mode: Player.PlayerMode
#var points_global = 200
#var coins_global = 50
#var lives_global = 5
#var time: int

# level beaten data -------------------------------------------------------------------------------
var level_1_1_beaten = false
var level_1_2_beaten = false
var level_1_3_beaten = false
var level_2_1_beaten = false
var level_2_2_beaten = false
var level_2_3_beaten = false
var level_3_1_beaten = false
var level_3_2_beaten = false
var level_3_3_beaten = false
var level_4_1_beaten = false
var level_4_2_beaten = false
var level_4_3_beaten = false
var level_S_R_beaten = false

# Coins reach this number a 1up is given
const num_coins_for_1up: int = 100

# maximum number of lives that mario can have. --------------------------------
const max_num_lives: int = 99

# maximum number of coins that mario can collect at once ----------------------
const max_num_coins: int = 100

#func _ready():

func respawn_player():
	if current_checkpoint != null:
		player.position = current_checkpoint.global_position
		
func restart():
	coins = 0
	score = 0
	lives = 5
	get_tree().reload_current_scene()

#func load_world():
	#get_tree().change_scene_to_file()

#func quit():
	#get_tree().quit()
	
func win():
	emit_signal("level_beaten")

func on_life_collected(life_gained:int):
	lives += life_gained
	emit_signal("gain_life", life_gained)

func lose_life(life_lost:int):
	lives -= life_lost
	emit_signal("lost_life", life_lost)

func on_points_scored(points_scored):
	score += points_scored
	emit_signal("gain_points", points_scored)

func on_coin_collected(coins_gained:int):
	coins += coins_gained
	emit_signal("gain_coins", coins_gained)
	if coins == num_coins_for_1up:
		on_life_collected(1)
		coins = 0
		
func level_complete():
	if level_finished == true:
		level_beaten.emit()
