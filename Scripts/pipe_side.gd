extends StaticBody2D

class_name PipeSide
## A sideways pipe (walk into it). Usually the way out of an underground room.
##
## WHERE IT GOES: fill in these two in the Inspector -
##   Destination Scene : pick the .tscn (or paste a uid://... string)
##   Destination Spawn : x, y where Mario appears in that scene
## Older setup still works: if Destination Scene is empty, the level script's
## _on_player_scene_under_change function decides where the pipe goes (like before).

@export_group("Destination")
@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn: Vector2 = Vector2.ZERO
@export var transition_pattern: String = "squares"
@export_group("Old setup (still works)")
@export var scene_overground: PackedScene
@export var spawn_point: Vector2
@export var start_from_pipe_exit: int
@export_group("")


func has_destination() -> bool:
	return destination_scene != ""


func travel() -> void:
	GameManager.travel_to(destination_scene, destination_spawn, {"pattern": transition_pattern, "speed": 4})


## Old handler some level scenes connect to. Travel is handled by the pipe now.
func _on_player_scene_under_change():
	pass
