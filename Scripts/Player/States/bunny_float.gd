extends PlayerState
## Bunny ears (Super Mario Land 2 carrot): hold jump while falling to float down slowly,
## flapping the ears. Let go of jump, or land, to stop.
##
## This is also the example of a power-up ABILITY as a state: the Bunny entry in PowerUps.gd
## names this state in "air_hold_state", and the Air state switches here when you hold jump.

@export var float_fall_speed: float = 28.0     ## how slowly Mario sinks while floating
@export var float_gravity: float = 140.0
@export var air_control: float = 1.0           ## 1 = normal left/right control while floating
@export var anim_float: StringName = &"bunny_float"   ## falls back to the jump animation if missing


func enter(_msg: Dictionary) -> void:
	player.velocity.y = minf(player.velocity.y, float_fall_speed)


func physics_update(delta: float) -> void:
	var input := Input.get_axis("left", "right")
	player.apply_horizontal(delta * air_control, input)
	player.velocity.y = move_toward(player.velocity.y, float_fall_speed, float_gravity * delta)
	player.move_and_slide()
	player.post_move(input)
	if not machine.is_in(name):
		return

	# Flapping ears animation (until you draw one, the normal jump frame is used)
	var sprite: AnimatedSprite2D = player.animated_sprite_2d
	if sprite.sprite_frames.has_animation(anim_float):
		sprite.play(anim_float)

	if player.is_on_floor():
		player.update_collision_shapes(false)
		machine.transition_to(&"Ground")
	elif not Input.is_action_pressed("jump") or player.player_mode != PlayerUpdated.PlayerMode.BUNNY:
		machine.transition_to(&"Air")
