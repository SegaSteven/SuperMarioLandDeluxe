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
var current_checkpoint: Checkpoint      # the checkpoint node touched (only valid until the scene reloads)

# The last checkpoint touched in the level being played. Kept when Mario dies (the level
# reloads and he starts here) and when he goes down pipes; cleared when he goes back to the
# map or finishes the level.
var checkpoint_scene: String = ""       # the scene the checkpoint is in (res://...tscn)
var checkpoint_position: Vector2 = Vector2.ZERO
var checkpoint_name: String = ""         # its node path in that scene

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
	clear_checkpoint()
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

## Puts Mario at the checkpoint if one was touched in THIS scene, otherwise at spawn_point.
## Level scripts call this in _ready (the player also does it by itself).
func respawn_player():
	if not is_instance_valid(player):
		return
	if has_checkpoint_in(_scene_of(player)):
		player.global_position = checkpoint_position
		if player.has_method("snap_to_floor"):
			player.snap_to_floor()
	elif spawn_point != Vector2.ZERO:
		player.global_position = spawn_point


## Called by a Checkpoint when Mario touches it. Returns true if it became the new one
## (a checkpoint further back in the level doesn't replace one further on).
func set_checkpoint(cp: Node2D, spawn: Vector2, only_forward: bool = true) -> bool:
	var scene := _scene_of(cp)
	if only_forward and checkpoint_scene == scene and spawn.x < checkpoint_position.x:
		return false
	checkpoint_scene = scene
	checkpoint_position = spawn
	checkpoint_name = String(cp.owner.get_path_to(cp)) if cp.owner else String(cp.name)
	current_checkpoint = cp as Checkpoint
	return true


func clear_checkpoint() -> void:
	checkpoint_scene = ""
	checkpoint_position = Vector2.ZERO
	checkpoint_name = ""
	current_checkpoint = null


func has_checkpoint() -> bool:
	return checkpoint_scene != ""


func has_checkpoint_in(scene_path: String) -> bool:
	return checkpoint_scene != "" and checkpoint_scene == scene_path


## True if this checkpoint node is the one Mario last touched.
func is_current_checkpoint(cp: Node) -> bool:
	if not has_checkpoint_in(_scene_of(cp)):
		return false
	var path := String(cp.owner.get_path_to(cp)) if cp.owner else String(cp.name)
	return path == checkpoint_name


## Where Mario should start again after losing a life.
##   checkpoint touched -> its level (even if he died down a pipe), at the checkpoint
##   no checkpoint      -> "" = reload the scene he died in
func death_restart_scene() -> String:
	if has_checkpoint() and ResourceLoader.exists(checkpoint_scene):
		return checkpoint_scene
	return ""


## The level scene a node belongs to (its owner's file, or the running scene's).
func _scene_of(n: Node) -> String:
	if n == null:
		return ""
	if n.owner and n.owner.scene_file_path != "":
		return n.owner.scene_file_path
	if n.is_inside_tree() and n.get_tree().current_scene:
		return n.get_tree().current_scene.scene_file_path
	return n.scene_file_path

func start_level():
	level_finished = false
	level_started.emit()

func win():
	level_finished = true
	clear_checkpoint()
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
	# Pipes and doors inside a level keep the checkpoint; going to a map forgets it
	if scene.contains("WorldScenes") or scene.ends_with("_map.tscn"):
		clear_checkpoint()
	SceneManager.change_scene(scene, transition)


func handle_game_over():
	reset_game_state()
	get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
