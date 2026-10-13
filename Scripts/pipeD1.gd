extends StaticBody2D

class_name PipeD1
## A pipe Mario can go DOWN into (stand on it and hold down).
##
## WHERE IT GOES: fill in these two in the Inspector -
##   Destination Scene : pick the .tscn (or paste a uid://... string)
##   Destination Spawn : x, y where Mario appears in that scene
## Leave Destination Scene empty to use the old way (the level script's
## _on_player_scene_over_d_1_change function decides).

const TOP_PIPE_HEIGHT = 8

@export_group("Destination")
@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn: Vector2 = Vector2.ZERO
@export var transition_pattern: String = "squares"
@export_group("")

@export var pipe_id: int
@export var height = 0
@export var is_traversable = false

@onready var collision_shape_2d = $CollisionShape2D
@onready var pipe_body_sprite = $PipeBodySprite


func _ready():
	var region_rect = Rect2(pipe_body_sprite.region_rect)
	region_rect.size = Vector2(16, height + TOP_PIPE_HEIGHT)
	pipe_body_sprite.region_rect = region_rect
	pipe_body_sprite.position = Vector2(0, height / 2)


func has_destination() -> bool:
	return destination_scene != ""


func travel() -> void:
	GameManager.travel_to(destination_scene, destination_spawn, {"pattern": transition_pattern, "speed": 4})
