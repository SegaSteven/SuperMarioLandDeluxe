extends AnimatedSprite2D

class_name PlayerAnimatedSprite

var frame_count = 0

func trigger_animation(velocity: Vector2, direction: int, player_mode: Player.PlayerMode):
	var animation_prefix = Player.PlayerMode.keys()[player_mode].to_snake_case()
	
	if not get_parent().is_on_floor():
		play("%s_jump" % animation_prefix)
		
		
	# Handles slide animations
	elif sign(velocity.x) != sign(direction) && velocity.x != 0 && direction != 0:
		play("%s_turn" % animation_prefix)
		scale.x = direction
	else:
	# handle the sprite direction
		if scale.x == 1 && sign(velocity.x) == -1:
			scale.x = -1
		else:
			flip_h = true
		if scale.x == -1 && sign(velocity.x) == 1:
			scale.x = 1
		else:
			flip_h = false
		
		#if scale.x == 1 && sign(velocity.x) == -1:
			#scale.x = -1
		#elif scale.x == -1 && sign(velocity.x) == 1:
			#scale.x = 1
		
		# handle run and idle animations
		if velocity.x != 0:
			play("%s_run" % animation_prefix)
		elif Input.is_action_pressed("down"):
			play("%s_down" % animation_prefix)
		else:
			play("%s_idle" % animation_prefix)
			
func reset_player_properties():
	offset = Vector2.ZERO
	get_parent().set_physics_process(true)
	get_parent().set_collision_layer_value(1, true)
	frame_count = 0
