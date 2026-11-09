extends Node2D
## Autoload "OverworldMan": remembers overworld progress between scenes, and saves it to disk
## so finished levels and star coins are still there next time the game is opened.
##
## SAVE FILES: there are 3 (one per UFO in the load room). current_slot is the one being
## played; every change (level beaten, star coin, unlock, switch) is written to it straight
## away. Files live at user://save_slot_1.cfg ... user://save_slot_3.cfg.

const SLOT_COUNT := 3
const SLOT_PATH := "user://save_slot_%d.cfg"
const OLD_SAVE_PATH := "user://save_progress.cfg"      ## the single save from before (moved to slot 1)

## The 12 main levels (level_name on their MapNodes). The load room counts how many are beaten.
const MAIN_LEVELS: Array[String] = [
	"1-1", "1-2", "1-3", "2-1", "2-2", "2-3",
	"3-1", "3-2", "3-3", "4-1", "4-2", "4-3",
]
## The 5 Star Road bonus levels. Give their MapNodes these level names (or change the list).
## Once any is beaten the load room shows a star and how many (star 5 = everything done).
const STAR_ROAD_LEVELS: Array[String] = ["STAR 1", "STAR 2", "STAR 3", "STAR 4", "STAR 5"]
## Switch colours shown as little blocks under each UFO (see PowerUps.SWITCH_COLORS).
const SAVE_SWITCHES: Array[String] = ["blue", "red", "pink"]

## Which save file is being played (1, 2 or 3).
var current_slot: int = 1
## The map scene Mario was last on (so continuing a file goes back to that map).
var last_map_scene: String = ""

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
	_move_old_save()
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
func slot_path(slot: int) -> String:
	return SLOT_PATH % slot


func slot_exists(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


## Writes the current file. Called automatically whenever something changes.
func save_progress() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("progress", "beaten", beaten)
	cfg.set_value("progress", "star_coins", star_coins)
	cfg.set_value("progress", "unlocks", unlocks)
	cfg.set_value("map", "last_node_name", last_node_name)
	cfg.set_value("map", "last_map_scene", last_map_scene)
	cfg.save(slot_path(current_slot))


func load_progress() -> void:
	_clear_memory()
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(current_slot)) != OK:
		return
	beaten = cfg.get_value("progress", "beaten", {})
	star_coins = cfg.get_value("progress", "star_coins", {})
	unlocks = cfg.get_value("progress", "unlocks", {})
	last_node_name = cfg.get_value("map", "last_node_name", "")
	last_map_scene = cfg.get_value("map", "last_map_scene", "")


## Starts playing a save file. Returns true if it was a NEW (empty) file - it's created now,
## so its UFO shows 0 straight away.
func select_slot(slot: int) -> bool:
	current_slot = clampi(slot, 1, SLOT_COUNT)
	var is_new := not slot_exists(current_slot)
	load_progress()
	if is_new:
		save_progress()
	return is_new


## Deletes a save file for good (the SAM cannon in the load room uses this).
func delete_slot(slot: int) -> void:
	if slot_exists(slot):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(slot_path(slot)))
	if slot == current_slot:
		_clear_memory()


## What the load room shows for a file:
##   {"exists": bool, "levels": 0-12, "star_levels": 0-5, "switches": {"blue": bool, ...}}
func slot_summary(slot: int) -> Dictionary:
	var out := {"exists": false, "levels": 0, "star_levels": 0, "switches": {}}
	for c in SAVE_SWITCHES:
		out.switches[c] = false
	var cfg := ConfigFile.new()
	if cfg.load(slot_path(slot)) != OK:
		return out
	out.exists = true
	var b: Dictionary = cfg.get_value("progress", "beaten", {})
	var u: Dictionary = cfg.get_value("progress", "unlocks", {})
	for id in MAIN_LEVELS:
		if b.get(id, false):
			out.levels += 1
	for id in STAR_ROAD_LEVELS:
		if b.get(id, false):
			out.star_levels += 1
	for c in SAVE_SWITCHES:
		out.switches[c] = u.get("switch_" + c, false)
	return out


## Wipes the CURRENT file (memory and disk). Testing / a "New Game" button.
func reset_progress() -> void:
	delete_slot(current_slot)
	_clear_memory()


func _clear_memory() -> void:
	beaten = {}
	star_coins = {}
	unlocks = {}
	pending_reveals.clear()
	last_node_name = ""
	last_map_scene = ""
	spawn_point = Vector2.ZERO


## The game used to have one save file. If it's there, it becomes file 1.
func _move_old_save() -> void:
	if FileAccess.file_exists(OLD_SAVE_PATH) and not slot_exists(1):
		DirAccess.rename_absolute(ProjectSettings.globalize_path(OLD_SAVE_PATH),
			ProjectSettings.globalize_path(slot_path(1)))
