extends Node2D
## Autoload "OverworldMan": remembers overworld progress between scenes, and saves it to disk
## so finished levels and star coins are still there next time the game is opened.

const SAVE_PATH := "user://save_progress.cfg"

## Emitted the moment something is unlocked (colour blocks listen to turn solid straight away).
signal unlocked(key: String)

@export var level_name: String
@export var area_name: String
@export var level_scene_path : String
var spawn_point : Vector2

## Which MapNode Mario was standing on when he entered a level (so he comes back there).
var last_node_name: String = ""
## How many star coins the level Mario is standing on has (0 = none, e.g. the dock).
var current_star_coin_total: int = 0

## Levels beaten so far, by level name: {"1-1": true, ...}
var beaten: Dictionary = {}
## Star coins saved per level: {"1-1": [true, false, true], ...}
var star_coins: Dictionary = {}
## Unlock names collected so far (secret exits, Star Road, power-ups): {"star_road_1": true, ...}
var unlocks: Dictionary = {}
## Unlocks earned since the map was last shown - their hidden paths play a reveal animation.
var pending_reveals: Array[String] = []


func _ready() -> void:
	load_progress()


# --- Finished levels ---------------------------------------------------------
func mark_beaten(level_id: String) -> void:
	if level_id == "":
		return
	beaten[level_id] = true
	save_progress()


func is_beaten(level_id: String) -> bool:
	return beaten.get(level_id, false)


# --- Star coins -------------------------------------------------------------
## coin_index is 0, 1 or 2
func has_star_coin(level_id: String, coin_index: int) -> bool:
	var coins: Array = star_coins.get(level_id, [])
	return coin_index < coins.size() and coins[coin_index]


## [bool, bool, bool] for the level (missing levels = all false)
func star_coins_for(level_id: String, count: int = 3) -> Array:
	var out: Array = []
	for i in count:
		out.append(has_star_coin(level_id, i))
	return out


func star_coin_count(level_id: String) -> int:
	return star_coins_for(level_id).count(true)


## Called when a level is finished: saves the coins picked up on that run.
func commit_star_coins(level_id: String, collected: Array) -> void:
	if level_id == "" or collected.is_empty():
		return
	var coins: Array = star_coins.get(level_id, [false, false, false]).duplicate()
	for i in collected:
		while coins.size() <= i:
			coins.append(false)
		coins[i] = true
	star_coins[level_id] = coins
	save_progress()


# --- Unlocks (secret exits, Star Road, power-ups) -----------------------------
## Unlock something by name, e.g. "star_road_1" or "powerup_bunny". Saved straight away.
func unlock(key: String) -> void:
	key = key.strip_edges()
	if key == "" or unlocks.get(key, false):
		return
	unlocks[key] = true
	if not pending_reveals.has(key):
		pending_reveals.append(key)
	save_progress()
	unlocked.emit(key)


func is_unlocked(key: String) -> bool:
	return key == "" or unlocks.get(key, false)


# --- Saving -----------------------------------------------------------------
func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "beaten", beaten)
	cfg.set_value("progress", "star_coins", star_coins)
	cfg.set_value("progress", "unlocks", unlocks)
	cfg.save(SAVE_PATH)


func load_progress() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(SAVE_PATH) != OK:
		return
	beaten = cfg.get_value("progress", "beaten", {})
	star_coins = cfg.get_value("progress", "star_coins", {})
	unlocks = cfg.get_value("progress", "unlocks", {})


## Wipes all saved progress (call from a "New Game" button, or the debugger while testing).
func reset_progress() -> void:
	beaten.clear()
	star_coins.clear()
	unlocks.clear()
	pending_reveals.clear()
	last_node_name = ""
	spawn_point = Vector2.ZERO
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SAVE_PATH))
