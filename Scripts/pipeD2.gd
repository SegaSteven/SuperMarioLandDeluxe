extends StaticBody2D

class_name PipeD2

const TOP_PIPE_HEIGHT = 8

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
