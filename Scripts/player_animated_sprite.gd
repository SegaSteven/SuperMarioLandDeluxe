extends AnimatedSprite2D

class_name PlayerAnimatedSprite
## Picks Mario's animation from his velocity. Called every physics frame by the player.
## Animation names are "<prefix>_<action>": small_run, big_jump, shooting_idle, fire_turn...
## The prefix for each power-up comes from Scripts/Player/PowerUps.gd (anim_prefix). If an
## animation doesn't exist yet (e.g. you haven't drawn "bunny_run"), its fallback_prefix is used,
## so new power-ups work with placeholder art straight away.

var _prefix: String = "small"
var _fallback: String = "small"


func trigger_animation(velocity: Vector2, direction: float, player_mode: int, shoot_pose: bool = false) -> void:
	if player_mode == 0:
		_prefix = "small"
		_fallback = "small"
	else:
		var data := PowerUps.for_mode(player_mode)
		_prefix = data.get("anim_prefix", "big")
		_fallback = data.get("fallback_prefix", "big")

	var body := get_parent() as CharacterBody2D
	var on_floor: bool = body != null and body.is_on_floor()

	# Facing
	if direction > 0.0:
		flip_h = false
	elif direction < 0.0:
		flip_h = true
	elif absf(velocity.x) > 1.0:
		flip_h = velocity.x < 0.0

	# Throwing something
	if shoot_pose and sprite_frames.has_animation("shoot"):
		play("shoot")
		speed_scale = 1.0
		return

	# Airborne
	if not on_floor:
		play_action("jump")
		speed_scale = 1.0
		return

	# Skidding: pushing against the way we're moving
	if direction != 0.0 and absf(velocity.x) > 20.0 and signf(velocity.x) != signf(direction):
		play_action("turn")
		speed_scale = 1.0
		return

	# Running / walking
	if absf(velocity.x) > 1.0:
		play_action("run")
		speed_scale = clampf(absf(velocity.x) / 40.0, 0.6, 3.0)
		return

	# Crouch (not small Mario)
	if Input.is_action_pressed("down") and player_mode != 0:
		play_action("down")
		speed_scale = 1.0
		return

	play_action("idle")
	speed_scale = 1.0


## Plays "<prefix>_<action>", falling back to the power-up's fallback prefix, then to idle.
func play_action(action: String) -> void:
	for anim in ["%s_%s" % [_prefix, action], "%s_%s" % [_fallback, action], "%s_idle" % _prefix, "%s_idle" % _fallback]:
		if sprite_frames.has_animation(anim):
			play(anim)
			return


## Helper to play an animation only if it exists, otherwise use a fallback
func play_with_fallback(anim_name: String, fallback: String) -> void:
	if sprite_frames.has_animation(anim_name):
		play(anim_name)
	else:
		play(fallback)


func reset_player_properties() -> void:
	offset = Vector2.ZERO
	var parent := get_parent()
	if parent:
		parent.set_physics_process(true)
		parent.set_collision_layer_value(1, true)
		parent.modulate.a = 1.0
