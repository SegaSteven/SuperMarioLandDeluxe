extends CharacterBody2D

class_name Superball

@onready var ray_cast_2d = $CollisionShape2D
@onready var player: Player = $Player

@export var horizontal_speed = 120
@export var vertical_speed = 120
var amplitude = 20
var is_moving_up = false

var direction
var vertical_movement_start_position

@onready var enemy = preload("res://Scripts/enemy.gd")
func _ready():
	$Fireball.play()
	velocity = (Vector2(horizontal_speed * direction, vertical_speed))

func _physics_process(delta):
	#position.x += delta * horizontal_speed * direction
	var collision_info = move_and_collide(velocity * delta)
	if collision_info:
		velocity = velocity.bounce(collision_info.get_normal())


func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_area_2d_body_entered(body: Enemy):
	body.die_from_hit()
	player.spawn_points_label_bonus(body.score)
	queue_free()
