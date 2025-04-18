extends LevelData

class_name Level1_1U1

@onready var player_camera = $Camera2D
@onready var player_mode = Player.PlayerMode
@onready var flash = $Camera2D/Flash
@onready var ui_hide = $Camera2D/UI
@onready var pauseSFX = $Pause/PauseSFX

# Pipe Settings
@export var scene_overground = "res://Scenes/Levels/1-1.tscn"
@export var spawn_point: Vector2

# Pipe Node List
@onready var Pipe1 = $PipeSide

# Called when the node enters the scene tree for the first time.
func _ready():
	pause_label.hide()
	ui_hide.hide()
	GameManager.respawn_player()
	player_mode = GameManager.player_mode
	player_camera.reset_smoothing()
	ui_hide.show()

# Deals with pausing of game --------------------------------------------------
func _input(event):
		if event.is_action_pressed("Pause"):
			pauseSFX.play()
			swap_pause_state()

# changes scene ---------------------------------------------------------------
func _on_player_scene_under_change():
	GameManager.spawn_point = spawn_point
	SceneManager.change_scene(scene_overground, {"pattern": "squares", "speed": 4})
