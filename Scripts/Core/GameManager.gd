extends Node

# Signals (Using modern syntax)
signal gain_coins(total: int)
signal gain_life(total: int)
signal lost_life(total: int)
signal gain_points(total: int)
signal level_beaten()
signal level_started()

# Player Stats
var coins: int = 0
var score: int = 0
var lives: int = 5
var superstar: bool = false

# Player State Persistence
var player : CharacterBody2D
var player_mode: PlayerUpdated.PlayerMode = PlayerUpdated.PlayerMode.SMALL
var spawn_point: Vector2 = Vector2.ZERO
var current_checkpoint: Checkpoint

# Level Progression
var level_finished: bool = false
var levels_beaten = {
	"1-1": false, "1-2": false, "1-3": false,
	"2-1": false, "2-2": false, "2-3": false,
	"3-1": false, "3-2": false, "3-3": false,
	"4-1": false, "4-2": false, "4-3": false
}

# Constants
const COINS_FOR_1UP: int = 100
const MAX_LIVES: int = 99

func _ready():
	# Standard initialization
	reset_game_state()

func reset_game_state():
	coins = 0
	score = 0
	lives = 5
	player_mode = PlayerUpdated.PlayerMode.SMALL
	level_finished = false

# --- Player Logic ---

func on_coin_collected(amount: int):
	coins += amount
	if coins >= COINS_FOR_1UP:
		coins -= COINS_FOR_1UP
		on_life_collected(1)
	
	gain_coins.emit(coins)

func on_points_scored(amount: int):
	score += amount
	gain_points.emit(score)

func on_life_collected(amount: int):
	lives = clampi(lives + amount, 0, MAX_LIVES)
	gain_life.emit(lives)

func lose_life(amount: int):
	lives -= amount
	lost_life.emit(lives)
	if lives <= 0:
		handle_game_over()

# --- Level & Respawn Logic ---

func respawn_player():
	if player and current_checkpoint:
		player.global_position = current_checkpoint.global_position
	elif player and spawn_point != Vector2.ZERO:
		player.global_position = spawn_point

func win():
	level_finished = true
	level_beaten.emit()

func handle_game_over():
	# GameBoy Super Mario Land usually sends you back to the title screen
	reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
