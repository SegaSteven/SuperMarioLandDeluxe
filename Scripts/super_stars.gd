extends CharacterBody2D

class_name SuperStar

signal got_bonus(star)

@export var horizontal_speed = 20
@export var move_speed = 300
var gravity = 160
var vertical_movement_start_position
@onready var shape_case_2d = $ShapeCast2D
@onready var ray_cast_2dr: RayCast2D = $RayCast2DR
@onready var ray_cast_2dl: RayCast2D = $RayCast2DL
@onready var ray_cast_2dd: RayCast2D = $RayCast2DD
@onready var area_2d: Area2D = $Area2D

var player = Player



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$Blockhititem.play()
	velocity = Vector2(0, 0).normalized() * move_speed

func _process(delta):
	position.x += delta * horizontal_speed
	if is_on_floor():
		var collision = move_and_collide(velocity * delta)
		velocity.bounce(collision.get_normal())
		
	if ray_cast_2dl.is_colliding():
		horizontal_speed = 20
	
	if ray_cast_2dr.is_colliding():
		horizontal_speed = -20
	

func _physics_process(delta):
	if (!is_on_floor()):
		velocity.y += gravity * delta
	var collision = move_and_collide(velocity * delta)
	if collision:
		velocity = velocity.bounce(collision.get_normal())
	

func _on_area_2d_body_entered(body: Node2D) -> void:
	if body is Player:
		GameManager.superstar = true
		queue_free()
