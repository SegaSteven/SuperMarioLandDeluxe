extends StaticBody2D

class_name PipeSide




@export var scene_overground: PackedScene
@export var spawn_point: Vector2
@export var start_from_pipe_exit: int


func pipe_side_collision(body):
	(body as Player).handle_side_pipe_enterance_collision()

func _on_player_scene_under_change():
	GameManager.spawn_point = spawn_point
	SceneSwitcher.switch_scene(scene_overground)
