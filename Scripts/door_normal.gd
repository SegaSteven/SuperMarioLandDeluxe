extends Area2D

class_name DoorNormal

signal level_finished()
signal level_completed_signal()

@export var level_scene_path: String
@export var spawn_point: Vector2
@export var level_music : AudioStreamPlayer
var time_countdown: int = 0
@onready var bonustime_stagecomplete: AudioStreamPlayer = $BonustimeStagecomplete
var ui = UI
@export var beaten_data : GDScript

func _on_area_entered(area: Area2D) -> void:
	level_completed_signal.emit()
	get_tree().paused = true
	level_music.stop()
	$"LevelEnd".play()
	await get_tree().create_timer(5).timeout
	get_tree().paused = false
	OverworldMan.spawn_point = spawn_point
	SceneManager.change_scene(level_scene_path, {"pattern": "squares", "speed": 6})

	
