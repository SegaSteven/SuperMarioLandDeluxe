extends LevelData

class_name Level_1_2

@onready var piped1_script = preload("res://Scripts/pipeD1.gd")
@onready var piped2_sciprt = preload("res://Scripts/pipeD2.gd")
@onready var player_camera = $Camera2D
@onready var player_mode = Player.PlayerMode
@onready var flash = $Camera2D/Flash
@onready var ui_hide = $Camera2D/UI
@onready var pauseSFX = $Pause/PauseSFX

# Pipe Settings
@export var scene_underground1 = "res://Scenes/Levels/1-1_Under.tscn"
@export var scene_underground2 = "res://Scenes/Levels/1-1_Under_2.tscn"
@export var spawn_point1: Vector2
@export var spawn_point2: Vector2

# Pipe Node List
@onready var Pipe1 = $Pipes/PipeD1
@onready var Pipe2 = $Pipes/PipeD2

# Called when the node enters the scene tree for the first time.
func _ready():
	player_camera.reset_smoothing()
	pause_label.hide()
	ui_hide.hide()
	level_music.stop()
	GameManager.respawn_player()
	player_mode = GameManager.player_mode
	var tween = get_tree().create_tween()
	tween.tween_property(flash, "modulate:a", 1, 0.2)
	tween.chain().tween_property(flash, "modulate:a", 0, .1).finished
	await get_tree().create_timer(.2).timeout
	level_music.play()
	ui_hide.show()
	level_start.emit()
	

#func _on_player_playermode():

# Deals with pausing of game --------------------------------------------------
func _input(event):
		if event.is_action_pressed("Pause"):
			pauseSFX.play()
			swap_pause_state()


# PIPE DATA FOR SWITCHING SCENES ---------------------------------------------

func _on_player_scene_over_d_1_change():
	GameManager.spawn_point = spawn_point1
	SceneManager.change_scene(scene_underground1, {"pattern": "squares", "speed": 4})

func _on_player_scene_over_d_2_change():
	GameManager.spawn_point = spawn_point2
	SceneManager.change_scene(scene_underground2, {"pattern": "squares", "speed": 4})


func _on_player_super_mode_play() -> void:
	level_music.stop()


func _on_player_super_mode_stop() -> void:
	level_music.play()
