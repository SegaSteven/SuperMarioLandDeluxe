extends Enemy

class_name ArrowDrop
## The spear Bunbun drops. Falls straight down and only hurts Mario: it has no collision with
## the level, so it goes straight through the ground, blocks and platforms (more dangerous).
## It's removed once it's below the bottom of the screen. Can't be stomped.

@export var fall_speed: float = 50.0


func _on_ready() -> void:
	can_be_stomped = false
	immune_to_projectiles = true
	score = 0
	always_active = true
	collision_mask = 0          # nothing in the level stops it (Mario still finds it as an enemy)


func _alive_physics(delta: float) -> void:
	velocity = Vector2(0, fall_speed)
	global_position += velocity * delta
	var cam := get_viewport().get_camera_2d()
	if cam:
		var bottom := cam.get_screen_center_position().y + get_viewport_rect().size.y * 0.5 / cam.zoom.y
		if global_position.y > bottom + 16.0:
			queue_free()
