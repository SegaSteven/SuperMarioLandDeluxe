extends AnimatedSprite2D

class_name PlayerAnimatedMapSprite

var frame_count = 0

func trigger_animation(velocity: Vector2, direction: int):

	# handle the sprite direction
		if scale.x == 1 && sign(velocity.x) == -1:
			scale.x = -1
		else:
			flip_h = true
		if scale.x == -1 && sign(velocity.x) == 1:
			scale.x = 1
		else:
			flip_h = false
	
		if velocity.y < 0:
			play("Down")
		else:
			play("Up")
