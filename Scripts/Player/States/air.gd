extends PlayerState
## Jumping and falling (including the bounce after a stomp).

var _coyote_left: float = 0.0


func enter(msg: Dictionary) -> void:
	# Walked off a ledge: allow a late jump for a few frames
	_coyote_left = player.coyote_time if msg.get("coyote", false) else 0.0


func physics_update(delta: float) -> void:
	if player.wants_to_climb():
		machine.transition_to(&"Climb")
		return
	_coyote_left = maxf(_coyote_left - delta, 0.0)
	if _coyote_left > 0.0 and player.wants_to_jump():
		_coyote_left = 0.0
		player.start_jump()

	# Short hop when the button is let go early
	if Input.is_action_just_released("jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.jump_cut

	# Power-ups with a "hold jump while falling" ability (bunny ears float)
	var hold := player.air_hold_state()
	if hold != &"" and player.velocity.y > 0.0 and Input.is_action_pressed("jump") and machine.has_state(hold):
		machine.transition_to(hold)
		return

	player.run_movement(delta)
	if not machine.is_in(name):
		return

	if player.is_on_floor() and player.velocity.y >= 0.0:
		player.update_collision_shapes(false)
		machine.transition_to(&"Ground")
