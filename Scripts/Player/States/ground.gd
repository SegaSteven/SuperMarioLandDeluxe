extends PlayerState
## Standing, walking, running, skidding and crouching.


func physics_update(delta: float) -> void:
	if player.wants_to_climb():
		machine.transition_to(&"Climb")
		return
	if player.wants_to_jump():
		player.start_jump()
		machine.transition_to(&"Air")
		return

	player.run_movement(delta)
	if not machine.is_in(name):
		return   # something during the move changed state (pipe, damage, death...)

	if not player.is_on_floor():
		machine.transition_to(&"Air", {"coyote": true})
