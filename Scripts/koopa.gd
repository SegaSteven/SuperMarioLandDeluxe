extends Enemy

class_name Koopa

@export var score = 100

var in_a_shell = false

const KOOPA_SHELL_COLLISION_SHAPE_POSITION = Vector2(0,6)
const KOOPA_EXPLODE_COLLISION_SHAPE_POSITION = Vector2(0,3)
const KOOPA_SHELL_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/koopa_shell_collision_shape.tres")
const KOOPA_FULL_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/koopa_full_collision_shape.tres")
const KOOPA_EXPLODE_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/koopa_explode_collision_shape.tres")
@onready var collision_shape_2d = $CollisionShape2D

func _ready():
	set_process(false)
	self.add_to_group("enemy")
	collision_shape_2d.shape = KOOPA_FULL_COLLISION_SHAPE

func die():
	if !in_a_shell:
		in_a_shell = true
		super.die()
		await get_tree().create_timer(1.5).timeout
	
	if in_a_shell:
		set_collision_layer_value(3, false)
		set_collision_mask_value(1, false)
		self.remove_from_group("enemy")
		self.add_to_group("koopabomb")
		super.koopa_explode()
		set_collision_layer_value(3, true)
		set_collision_mask_value(1, true)
		collision_shape_2d.set_deferred("shape", KOOPA_EXPLODE_COLLISION_SHAPE)
		collision_shape_2d.set_deferred("position", KOOPA_EXPLODE_COLLISION_SHAPE_POSITION)
		GameManager.on_points_scored(score)
		
	in_a_shell = true
	
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	set_process(true)
	


func _on_body_entered(body: Superball):
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(4, false)
	set_collision_mask_value(5, false)
	set_collision_mask_value(7, false)
	die_from_hit()
