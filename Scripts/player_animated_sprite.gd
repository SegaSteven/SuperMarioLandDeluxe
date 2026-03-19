extends AnimatedSprite2D

class_name PlayerAnimatedSprite

# Map the Enum integers to strings for animation naming
const PREFIXES = {
	0: "small",    # PlayerUpdated.PlayerMode.SMALL
	1: "big",      # PlayerUpdated.PlayerMode.BIG
	2: "shooting"  # PlayerUpdated.PlayerMode.SHOOTING
}

func trigger_animation(velocity: Vector2, direction: float, player_mode: int):
	# 1. Determine the prefix based on current mode
	var prefix = PREFIXES.get(player_mode, "small")
	
	# 2. Update Sprite Direction
	if direction > 0:
		flip_h = false # Face Right
	elif direction < 0:
		flip_h = true  # Face Left
	elif abs(velocity.x) > 1:
		flip_h = velocity.x < 0
	
	var parentjump = get_parent() as CharacterBody2D
	
	if parentjump and not parentjump.is_on_floor():
		play("%s_jump" % prefix)
		speed_scale = 1.2
	
	elif not is_zero_approx(velocity.x):
		play("%s_run" % prefix)
		
		# TUNING FOR SPEED:
		var walk_speed_scale = 5  # Speed scale when walking (1.0 is normal, 2.0 is double)
		var run_speed_scale = 520   # Speed scale when holding the 'action' button
		
		# Detect if we are running (usually speed > 100 in your script)
		if abs(velocity.x) > 100:
			speed_scale = run_speed_scale
		else:
			speed_scale = walk_speed_scale
		
	else:
		play("%s_idle" % prefix)
		speed_scale = 1.0

	# 3. Animation State Machine
	var parentstate = get_parent() as CharacterBody2D
	
	# AIRBORNE
	if parentstate and not parentstate.is_on_floor():
		play_with_fallback("%s_jump" % prefix, "%s_idle" % prefix)
		speed_scale = 1.0

	# SKIDDING (Pressing opposite direction of momentum)
	elif direction != 0 and not is_zero_approx(velocity.x) and sign(velocity.x) != sign(direction):
		if abs(velocity.x) > 20: # Only skid if moving fast enough
			play_with_fallback("%s_turn" % prefix, "%s_run" % prefix)
		else:
			play("%s_run" % prefix)
		speed_scale = 1.5 # Skidding legs move faster

	# MOVING
	elif not is_zero_approx(velocity.x):
		play("%s_run" % prefix)
		# Leg speed scales with horizontal velocity
		speed_scale = clamp(abs(velocity.x) / 100.0, 0.5, 2.0)

	# CROUCHING
	elif Input.is_action_pressed("down") and player_mode != 0: # 0 is SMALL
		play("%s_down" % prefix)
		speed_scale = 1.0

	# IDLE
	else:
		play("%s_idle" % prefix)
		speed_scale = 1.0

## Helper to play an animation only if it exists, otherwise use a fallback
func play_with_fallback(anim_name: String, fallback: String):
	if sprite_frames.has_animation(anim_name):
		play(anim_name)
	else:
		play(fallback)

func reset_player_properties():
	offset = Vector2.ZERO
	var parentreset = get_parent()
	if parentreset:
		# Godot 4.3 specific naming
		parentreset.set_physics_process(true)
		parentreset.set_collision_layer_value(1, true)
		parentreset.modulate.a = 1.0
