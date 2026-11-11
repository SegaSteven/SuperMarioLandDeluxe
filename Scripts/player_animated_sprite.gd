extends AnimatedSprite2D

class_name PlayerAnimatedSprite
## Picks Mario's animation from his velocity. Called every physics frame by the player.
## Animation names are "<prefix>_<action>": small_run, big_jump, shooting_idle, fire_turn...
## The prefix for each power-up comes from Scripts/Player/PowerUps.gd (anim_prefix). If an
## animation doesn't exist yet (e.g. you haven't drawn "bunny_run"), its fallback_prefix is used,
## so new power-ups work with placeholder art straight away.
##
## THE SETS (each has _idle, _run, _jump, _turn, _down, _climb):
##   small_   small Mario              big_      big Mario (mushroom)
##   shooting_ superball flower (+climb) fire_   Fire Flower (copies of the shooting frames,
##                                              recoloured by the fire palette)
##   bunny_   bunny ears (+ bunny_float for the slow fall)
##   speed_   speed shoes - used on top of big/fire/bunny/superball while the shoes are on
##            (small Mario keeps his small frames)
## The new sets start as copies of the big frames: open Player > AnimatedSprite2D, pick one in
## the SpriteFrames panel and swap the frames for your own. Once a power-up has real frames,
## set its "tint" in PowerUps.gd to Color(1, 1, 1) so the placeholder colour goes away.

## Prefix used while the speed shoes are on (not for small Mario).
@export var speed_shoes_prefix: String = "speed"

## PALETTE SWAP - recolours Mario's frames for each power-up (the new sets are copies of the
## big frames, so this is what makes them look different until you draw your own).
## Palette From = the colours in your frames: the first 3 are big Mario's (red cap & shirt,
## blue overalls, dark shading), the next 3 are the superball frames' (blue cap & shirt, green
## overalls, dark green). Each power-up palette lists the colour to use instead, in the same
## order. (Fire Mario uses the superball/shooting frames, so its last 3 are the ones it sees.)
## Untick Palette Swap On once you've drawn real frames.
@export_group("Palette Swap")
@export var palette_swap_on: bool = true
@export var palette_from: PackedColorArray = PackedColorArray([
	Color("e6131a"), Color("457db0"), Color("173550"),
	Color("312caf"), Color("43b102"), Color("2c680c")])
@export var palette_fire: PackedColorArray = PackedColorArray([      ## orange
	Color("e85a00"), Color("457db0"), Color("173550"),
	Color("e85a00"), Color("457db0"), Color("173550")])
@export var palette_bunny: PackedColorArray = PackedColorArray([     ## pink
	Color("ff6fbf"), Color("457db0"), Color("173550"),
	Color("ff6fbf"), Color("457db0"), Color("173550")])
@export var palette_speed: PackedColorArray = PackedColorArray([     ## blue
	Color("2a6cf5"), Color("8fd3ff"), Color("3a8ac0"),
	Color("2a6cf5"), Color("8fd3ff"), Color("3a8ac0")])
## More power-ups: animation prefix -> palette, e.g. "cape": [yellow, ...]
@export var palette_extra: Dictionary[String, PackedColorArray] = {}
## Only recolour these actions (e.g. ["climb"]). Empty = every animation of that power-up.
@export var palette_only_actions: PackedStringArray = PackedStringArray()
@export_range(0.0, 0.5, 0.01) var palette_tolerance: float = 0.06
@export_group("")

const PALETTE_SHADER := preload("res://Shaders/palette_swap.gdshader")
var _palette_key: String = "-"
var _palette_material: ShaderMaterial

var _prefix: String = "small"
var _fallback: String = "small"
var _first: String = ""          # tried before _prefix (the speed shoes set)


## Works out which set of animations to use for this power-up.
func update_prefix(player_mode: int) -> void:
	if player_mode == 0:
		_prefix = "small"
		_fallback = "small"
	else:
		var data := PowerUps.for_mode(player_mode)
		_prefix = data.get("anim_prefix", "big")
		_fallback = data.get("fallback_prefix", "big")
	var body := get_parent()
	var shoes: bool = body != null and "speed_shoes_on" in body and body.speed_shoes_on
	_first = speed_shoes_prefix if shoes and player_mode != 0 else ""


## Climbing a ladder or vine: small_climb / big_climb / fire_climb... (moving = true animates)
func play_climb(player_mode: int, moving: bool) -> void:
	update_prefix(player_mode)
	play_action("climb")
	speed_scale = 1.0 if moving else 0.0


## Run animation speed for every form: 15 fps base (set on each *_run animation), played at
## Walk Fps at walking speed and Run Fps at full running speed (run button held).
@export var walk_fps: float = 22.0
@export var run_fps: float = 30.0


## Frames per second for the run animation at this speed (px/s), from Mario's walk / run speeds.
func _run_fps(speed: float) -> float:
	var body := get_parent()
	var walk: float = body.max_walk_speed if body and "max_walk_speed" in body else 60.0
	var run: float = body.max_run_speed if body and "max_run_speed" in body else 90.0
	if speed <= walk:
		return maxf(walk_fps * speed / walk, 8.0)
	return lerpf(walk_fps, run_fps, clampf((speed - walk) / maxf(run - walk, 1.0), 0.0, 1.0))


func trigger_animation(velocity: Vector2, direction: float, player_mode: int, shoot_pose: bool = false) -> void:
	update_prefix(player_mode)

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
		speed_scale = _run_fps(absf(velocity.x)) / maxf(sprite_frames.get_animation_speed(animation), 1.0)
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
	var names: Array = []
	if _first != "":
		names.append("%s_%s" % [_first, action])
	names.append_array(["%s_%s" % [_prefix, action], "%s_%s" % [_fallback, action]])
	if action == "climb":
		names.append_array(["%s_jump" % _prefix, "%s_jump" % _fallback])   # no climb frames yet
	names.append_array(["%s_idle" % _prefix, "%s_idle" % _fallback])
	for anim in names:
		if sprite_frames.has_animation(anim):
			play(anim)
			_update_palette(action)
			return


## The palette for a set of animations ("fire", "bunny", "speed"...), empty = none.
func palette_for(set_name: String) -> PackedColorArray:
	if not palette_swap_on:
		return PackedColorArray()
	match set_name:
		"fire": return palette_fire
		"bunny": return palette_bunny
		"speed": return palette_speed
	return palette_extra.get(set_name, PackedColorArray())


## True if this power-up mode is recoloured by a palette (the player then skips the old tint).
func has_palette_for_mode(player_mode: int) -> bool:
	if player_mode == 0:
		return false
	return not palette_for(PowerUps.for_mode(player_mode).get("anim_prefix", "")).is_empty()


func _update_palette(action: String) -> void:
	var key := _first if _first != "" else _prefix
	var colors := palette_for(key)
	if not palette_only_actions.is_empty() and not palette_only_actions.has(action):
		colors = PackedColorArray()
	var new_key := key if not colors.is_empty() else ""
	if new_key == _palette_key:
		return
	_palette_key = new_key
	if colors.is_empty():
		material = null
		return
	if _palette_material == null:
		_palette_material = ShaderMaterial.new()
		_palette_material.shader = PALETTE_SHADER
	var n := mini(mini(colors.size(), palette_from.size()), 8)
	_palette_material.set_shader_parameter("color_count", n)
	_palette_material.set_shader_parameter("from_colors", palette_from.slice(0, n))
	_palette_material.set_shader_parameter("to_colors", colors.slice(0, n))
	_palette_material.set_shader_parameter("tolerance", palette_tolerance)
	material = _palette_material


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
