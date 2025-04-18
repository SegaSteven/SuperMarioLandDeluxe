extends Area2D

class_name Enemy

@export var horizontal_speed = 20
@export var vertical_speed = 80

@onready var ray_cast_2d = $RayCast2D
@onready var ray_cast_L = $RayCast2DSideL
@onready var ray_cast_R = $RayCast2DSideR
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var collision = $CollisionShape2D
@onready var afb = $AFBs/AboutFaceBlock
@onready var death_box = $DeathBoxes/Deathbox

const gravityfall = 250

func _ready():
	set_process(false)

func _process(delta):
	gravity = gravityfall
	
	position.x -= delta * horizontal_speed
	
	if !ray_cast_2d.is_colliding():
		position.y += delta * vertical_speed
		
	if ray_cast_L.is_colliding():
		horizontal_speed = -20
		animated_sprite_2d.flip_h = true
		
	if ray_cast_R.is_colliding():
		horizontal_speed = 20
		animated_sprite_2d.flip_h = false
	
	if ray_cast_2d.is_colliding() is DeathBox:
		queue_free()
	
func die():
	horizontal_speed = 0
	vertical_speed = 0
	animated_sprite_2d.play("dead")
	$Enemykilled.play()
	
func die_from_hit():
	animated_sprite_2d.play("dead")
	set_collision_layer_value(3, false)
	set_collision_mask_value(3, false)
	
	rotation_degrees = 180
	vertical_speed = 0
	horizontal_speed = 0
	
	var die_tween = get_tree().create_tween()
	die_tween.tween_property(self, "position", position + Vector2(3, -10), .03)
	die_tween.chain().tween_property(self, "position", position + Vector2(5, -11), .05)
	die_tween.chain().tween_property(self, "position", position + Vector2(8, -13), .05)
	die_tween.chain().tween_property(self, "position", position + Vector2(15, -14), .08)
	die_tween.chain().tween_property(self, "position", position + Vector2(20, -12), .05)
	die_tween.chain().tween_property(self, "position", position + Vector2(25, -9), .03)
	die_tween.chain().tween_property(self, "position", position + Vector2(60, 500), 3)
	$Enemykilled.play()

func koopa_explode():
		animated_sprite_2d.play("explode")
		$Nokobomb.play()
		get_tree().create_timer(1).timeout.connect(queue_free)
		
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	set_process(true)
	
func _on_area_2d_body_entered(body: Superball):
	die_from_hit()
	queue_free()
