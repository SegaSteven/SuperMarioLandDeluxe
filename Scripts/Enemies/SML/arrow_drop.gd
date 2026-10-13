extends Enemy

class_name ArrowDrop
## The spear Bunbun drops. Falls straight down, hurts on touch, can't be stomped.

@export var fall_speed: float = 50.0


func _on_ready() -> void:
	can_be_stomped = false
	immune_to_projectiles = true
	score = 0
	always_active = true


func _alive_physics(delta: float) -> void:
	velocity = Vector2(0, fall_speed)
	move_and_slide()
	if get_slide_collision_count() > 0:
		queue_free()
