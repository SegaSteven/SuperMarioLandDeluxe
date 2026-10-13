extends Node

signal gain_coins(total: int)
signal gain_life(total: int)
signal lost_life(total: int)
signal gain_points(total: int)
signal level_beaten()
signal level_started()

# Player stats ---------------------------------------------------------------
var coins: int = 0
var score: int = 0
var lives: int = 5
var superstar: bool = false

# Older scripts still read/write these
var points_global: int = 0
var coins_global: int = 0
var pre_level: String = ""

# Player state that survives scene changes -----------------------------------
var player: CharacterBody2D
var player_mode: PlayerUpdated.PlayerMode = PlayerUpdated.PlayerMode.SMALL
var spawn_point: Vector2 = Vector2.ZERO
var current_checkpoint: Checkpoint

# Star coins picked up in the level being played. Only saved when the level is finished
# (like New Super Mario Bros). Indexes 0, 1, 2.
var pending_star_coins: Array[int] = []

# Level progression ----------------------------------------------------------
var level_finished: bool = false
var levels_beaten = {
	"1-1": false, "1-2": false, "1-3": false,
	"2-1": false, "2-2": false, "2-3": false,
	"3-1": false, "3-2": false, "3-3": false,
	"4-1": false, "4-2": false, "4-3": false
}

const COINS_FOR_1UP: int = 100
const MAX_LIVES: int = 99

func _ready():
	reset_game_state()

func reset_game_state():
	coins = 0
	score = 0
	lives = 5
	player_mode = PlayerUpdated.PlayerMode.SMALL
	level_finished = false
	current_checkpoint = null
	spawn_point = Vector2.ZERO

# --- Scoring -----------------------------------------------------------------

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

## Takes a life AWAY. lose_life(1) = one life gone.
## (The old player called lose_life(-1), which actually ADDED a life.)
## This no longer changes scene by itself - the player decides when, after the death animation.
func lose_life(amount: int = 1):
	lives = maxi(lives - amount, 0)
	lost_life.emit(lives)

func is_game_over() -> bool:
	return lives <= 0

# --- Level / respawn ---------------------------------------------------------

func respawn_player():
	if not is_instance_valid(player):
		return
	if is_instance_valid(current_checkpoint):
		player.global_position = current_checkpoint.global_position
	elif spawn_point != Vector2.ZERO:
		player.global_position = spawn_point

func start_level():
	level_finished = false
	level_started.emit()

func win():
	level_finished = true
	current_checkpoint = null
	OverworldMan.commit_star_coins(OverworldMan.level_name, pending_star_coins)
	pending_star_coins.clear()
	level_beaten.emit()


## A star coin was touched. coin_index is 0, 1 or 2.
func collect_star_coin(coin_index: int) -> void:
	if not pending_star_coins.has(coin_index):
		pending_star_coins.append(coin_index)


## Called when entering a level from the map, and when Mario dies (coins not kept).
func clear_pending_star_coins() -> void:
	pending_star_coins.clear()

## Go to another scene: a level, an underground room, the bonus room or a map.
##   scene - "res://Scenes/Levels/1-2.tscn" or a UID like "uid://b3e2uv1pq2x1o"
##           (in the FileSystem dock: right-click a scene > Copy UID)
##   spawn - where Mario appears in that scene. For a map, any point near the MapNode.
##           Vector2.ZERO = use the scene's own starting position.
## Doors and pipes all call this, so changing how travel works only happens here.
func travel_to(scene: String, spawn: Vector2 = Vector2.ZERO, transition: Dictionary = {"pattern": "squares", "speed": 4}) -> void:
	if scene == "":
		push_warning("GameManager.travel_to: no destination scene set")
		return
	if not ResourceLoader.exists(scene):
		push_error("GameManager.travel_to: can't find scene '%s'" % scene)
		return
	if is_instance_valid(player) and "player_mode" in player:
		player_mode = player.player_mode
	spawn_point = spawn
	OverworldMan.spawn_point = spawn
	current_checkpoint = null
	SceneManager.change_scene(scene, transition)


func handle_game_over():
	reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
