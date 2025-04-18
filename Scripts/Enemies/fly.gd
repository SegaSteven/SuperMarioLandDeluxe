extends Enemy

class_name Fly

@export var score = 400

@onready var Flysprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var player: Player = $"../../Player"
@onready var mariocast_l: RayCast2D = $MariocastL
@onready var mariocast_r: RayCast2D = $MariocastR

@export var horizontal_move = 20
@export var vertical_move = 50
var amplitude = 20
var is_moving_up = false
var stopped = true

var direction = -1
var vertical_movement_start_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	self.add_to_group("enemy")
	Flysprite.play("default")

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	position.x += delta * horizontal_speed * direction
	horizontal_speed = 0
	
	if ray_cast_2d.is_colliding():
		stopped = true
		is_moving_up = false
		horizontal_speed = 0
		Flysprite.play("default")
		await get_tree().create_timer(1).timeout
		is_moving_up = true
		stopped = false
		vertical_movement_start_position = position
	
	if is_moving_up && stopped == false:
		horizontal_speed = 20
		position.y -= vertical_move * delta
		Flysprite.play("jump")
		await get_tree().create_timer(0.4).timeout
		is_moving_up = false
			
	if !is_moving_up && stopped == false:
		horizontal_speed = 20
		position.y += delta * vertical_move
		
	if mariocast_l.is_colliding():
		direction = -1
		
	if mariocast_r.is_colliding():
		direction = 1

func die():
	Flysprite.play("dead")
	horizontal_speed = 0
	horizontal_move = 0
	vertical_speed = 0
	vertical_move = 0
	set_collision_layer_value(3, false)
	set_collision_mask_value(4, false)
	set_collision_mask_value(5, false)
	super.die_from_hit()
	get_tree().create_timer(1.5).timeout.connect(queue_free)
	GameManager.on_points_scored(score)

func _on_body_entered(body: Superball):
	set_collision_layer_value(3, false)
	set_collision_mask_value(4, false)
	set_collision_mask_value(5, false)
	set_collision_mask_value(7, false)
	die_from_hit()


func _on_visible_on_screen_notifier_2d_2_screen_entered() -> void:
	set_process(true)


func _on_visible_on_screen_notifier_2d_2_screen_exited() -> void:
	queue_free()
