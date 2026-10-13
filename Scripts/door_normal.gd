extends Area2D

class_name DoorNormal
## A level exit. Super Mario Land levels have two: the normal exit (back to the map) and the
## upper bonus exit (to the bonus room). Both use this script and both count as beating the level.
## A SECRET exit works the same, and is usually given an "Unlocks" name that opens a hidden
## path on the map (a secret level, Star Road) or a new power-up ("powerup_bunny").
##
## WHERE IT GOES: fill in these two in the Inspector -
##   Level Scene Path : the scene to go to. Pick the .tscn or paste a uid://... string.
##                      e.g. the world map, or res://Scenes/bonus_room.tscn for the bonus exit.
##   Spawn Point      : x, y where Mario appears there. For the world map you can leave it at
##                      (0, 0) - Mario goes back to the tile he entered the level from.
##
## NOTE: the trigger box (CollisionShape2D) in door_normal.tscn sits about 2400px to the right of
## the door node itself. Move the CollisionShape2D, not just the door, when you place a new exit.

signal level_finished()
signal level_completed_signal()

enum ExitType { NORMAL, BONUS, SECRET }

@export_file("*.tscn") var level_scene_path: String = "res://Scenes/WorldScenes/world_map.tscn"
@export var spawn_point: Vector2 = Vector2.ZERO
@export var exit_type: ExitType = ExitType.NORMAL
## Unlock name(s) this exit gives, comma separated, e.g. "star_road_1" or "star_road_1, powerup_bunny".
## A map path or level icon with the same Required Unlock appears the next time you see the map.
@export var unlocks: String = ""
@export var level_music: AudioStreamPlayer
@export var fanfare_time: float = 5.0          ## seconds the "level end" music plays first
@export var transition_pattern: String = "squares"
## Count the time left into the score (Super Mario Land style). Settings are on the UI node.
@export var time_bonus: bool = true
## true = the clock counts down while the fanfare plays; false = after it.
@export var count_during_fanfare: bool = false
## Short pause after the count reaches 0, before leaving.
@export var pause_after_count: float = 0.6
@export var beaten_data: GDScript              ## (unused, kept so old scenes load)

var _used: bool = false


func _on_area_entered(area: Area2D) -> void:
	if _used:
		return
	# Only Mario's own hitbox opens the door - not enemies, torpedoes or superballs
	if not area.get_parent() is PlayerUpdated:
		return
	var mario: PlayerUpdated = area.get_parent()
	if mario.is_dead:
		return
	_used = true

	var ui: UI = UI.find(get_tree()) if time_bonus else null
	if ui:
		ui.stop_time()          # the clock freezes the moment Mario touches the exit
	GameManager.win()   # marks the level beaten on the map (via RunTimeLevel)
	for key in unlocks.split(",", false):
		OverworldMan.unlock(key)
	level_completed_signal.emit()
	level_finished.emit()

	var music := level_music
	if music == null:
		music = get_tree().current_scene.get_node_or_null("LevelMusic") as AudioStreamPlayer
	if music:
		music.stop()
	var fanfare := get_node_or_null("LevelEnd") as AudioStreamPlayer
	if fanfare:
		fanfare.process_mode = Node.PROCESS_MODE_ALWAYS
		fanfare.play()

	# Freeze the level while the fanfare plays (this door keeps running while paused)
	process_mode = Node.PROCESS_MODE_ALWAYS
	get_tree().paused = true
	if ui and count_during_fanfare:
		var fanfare_done := get_tree().create_timer(fanfare_time, true)
		await ui.tally_time_bonus()
		if fanfare_done.time_left > 0.0:
			await fanfare_done.timeout
	else:
		await get_tree().create_timer(fanfare_time, true).timeout
		if ui:
			await ui.tally_time_bonus()
	if ui:
		await get_tree().create_timer(pause_after_count, true).timeout
	get_tree().paused = false

	GameManager.travel_to(level_scene_path, spawn_point, {"pattern": transition_pattern, "speed": 6})
