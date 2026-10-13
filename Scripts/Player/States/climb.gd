extends PlayerState
## Climbing a vine (or anything in the "vines" group). Entered from Ground/Air by pressing Up
## while touching a vine. Up/Down to climb, Left/Right to let go sideways, Jump to jump off.
## At the top of a vine with a Destination Scene, Mario travels there.

@export var climb_speed: float = 40.0
@export var anim_climb: StringName = &"climb"      ## falls back to the jump frame if missing

var vine: Vine


func _init() -> void:
	allows_stomp = false


func enter(_msg: Dictionary) -> void:
	vine = player.touching_vine
	player.velocity = Vector2.ZERO
	if vine:
		player.global_position.x = vine.global_position.x


func physics_update(_delta: float) -> void:
	if vine == null or not is_instance_valid(vine):
		machine.transition_to(&"Air")
		return

	var v := Input.get_axis("Up", "down")
	player.velocity = Vector2(0, v * climb_speed)
	player.move_and_slide()
	player.check_contacts()
	if not machine.is_in(name):
		return

	# Top of the vine
	var feet := player.get_feet_y()
	if feet <= vine.top_y() + 2.0:
		player.global_position.y += (vine.top_y() + 2.0) - feet
		if vine.has_destination() and vine.is_fully_grown() and v < 0.0:
			machine.transition_to(&"Pipe", {"offset": Vector2(0, -16), "pipe": vine})
			return

	_animate(v)

	if Input.is_action_just_pressed("jump"):
		player.start_jump()
		machine.transition_to(&"Air")
	elif Input.get_axis("left", "right") != 0.0 and v == 0.0:
		machine.transition_to(&"Air")          # step off sideways
	elif player.is_on_floor() and v > 0.0:
		machine.transition_to(&"Ground")       # climbed down to the ground


func _animate(v: float) -> void:
	var sprite: AnimatedSprite2D = player.animated_sprite_2d
	if sprite.sprite_frames.has_animation(anim_climb):
		sprite.play(anim_climb)
	else:
		player.animate(0.0)
	sprite.speed_scale = 1.0 if v != 0.0 else 0.0


func exit() -> void:
	player.animated_sprite_2d.speed_scale = 1.0
