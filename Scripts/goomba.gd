extends Enemy

class_name Goomba

@export var score = 100

func _ready():
	set_process(false)
	self.add_to_group("enemy")

func die():
	super.die()
	
	set_collision_layer_value(3, false)
	set_collision_mask_value(4, false)
	set_collision_mask_value(5, false)
	get_tree().create_timer(1.5).timeout.connect(queue_free)
	GameManager.on_points_scored(score)
	
func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_visible_on_screen_notifier_2d_screen_entered():
	set_process(true)


func _on_body_entered(body: Superball):
	set_collision_layer_value(3, false)
	set_collision_mask_value(4, false)
	set_collision_mask_value(5, false)
	set_collision_mask_value(7, false)
	die_from_hit()
