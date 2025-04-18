extends Area2D

class_name Shroom

@export var horizontal_speed = 20
@export var max_vertical_speed = 120
@export var vertical_velocity_gain = .3
@onready var shape_case_2d = $ShapeCast2D
@onready var ray_cast_2dl: RayCast2D = $RayCast2DL
@onready var ray_cast_2dr: RayCast2D = $RayCast2DR


var allow_horizontal_movement = false
var vertical_speed = 0

func _ready():
	var spawn_tween = get_tree().create_tween()
	$Blockhititem.play()
	spawn_tween.tween_property(self, "position", position + Vector2(0, -5), .3)
	spawn_tween.tween_callback(func (): allow_horizontal_movement = true)
	

func _process(delta):
	if allow_horizontal_movement:
		position.x += delta * horizontal_speed
	
	if !shape_case_2d.is_colliding() && allow_horizontal_movement:
		vertical_speed = lerpf(vertical_speed, max_vertical_speed, vertical_velocity_gain)
		position.y += delta * vertical_speed
	else:
		vertical_speed = 0
	
	if ray_cast_2dl.is_colliding():
		horizontal_speed = 20
	if ray_cast_2dr.is_colliding():
		horizontal_speed = -20
