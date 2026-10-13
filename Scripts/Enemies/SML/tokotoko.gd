extends Enemy

class_name Tokotoko
## Tokotoko (World 3, Easton): a running moai statue. Once it sees Mario it sprints at him.

@export var run_speed: float = 55.0


func _on_activated() -> void:
	direction = direction_to_player()
	_face(direction)


func _alive_physics(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = direction * run_speed
	move_and_slide()
	_turn_if_blocked()
