extends PlayerState
## Growing (mushroom), getting a flower, or shrinking after a hit. Mario flickers between his
## old and new size.
## Enter with: machine.transition_to("Transform", {"mode": PlayerUpdated.PlayerMode.BIG, "damage": false})
##
## Mario KEEPS HIS MOMENTUM while this plays: he carries on running, jumping or falling and you
## can still steer him. Tick "Freeze On Power Up" / "Freeze On Damage" for the old NES-style
## pause instead (Mario stops in mid-air, then carries on with the speed he had).

@export var flicker_count: int = 5
@export var flicker_step: float = 0.07
@export var freeze_on_power_up: bool = false
@export var freeze_on_damage: bool = false

var _tween: Tween
var _show_mode: int = 0          # which size the flicker is showing right now
var _frozen: bool = false
var _saved_velocity: Vector2 = Vector2.ZERO


func _init() -> void:
	allows_contacts = false
	allows_damage = false


func enter(msg: Dictionary) -> void:
	var new_mode: PlayerUpdated.PlayerMode = msg.get("mode", PlayerUpdated.PlayerMode.BIG)
	var is_damage: bool = msg.get("damage", false)
	var old_mode: int = player.player_mode
	_frozen = freeze_on_damage if is_damage else freeze_on_power_up
	_saved_velocity = player.velocity
	if _frozen:
		player.velocity = Vector2.ZERO

	_show_mode = old_mode
	_tween = player.create_tween()
	for i in flicker_count:
		_tween.tween_callback(_show.bind(new_mode))
		_tween.tween_interval(flicker_step)
		_tween.tween_callback(_show.bind(old_mode))
		_tween.tween_interval(flicker_step)
	_tween.tween_callback(_finish.bind(new_mode, is_damage))


func physics_update(delta: float) -> void:
	if _frozen:
		_draw_flicker(0.0)
		return
	# Same movement as normal, minus shooting, pipes and enemy contacts
	var input_dir: float = Input.get_axis("left", "right")
	if Input.is_action_just_released("jump") and player.velocity.y < 0.0:
		player.velocity.y *= player.jump_cut
	player.apply_gravity(delta)
	player.apply_horizontal(delta, input_dir)
	player.move_and_slide()
	player._keep_inside_camera()
	_draw_flicker(input_dir)


func _show(mode: int) -> void:
	_show_mode = mode
	_draw_flicker(Input.get_axis("left", "right") if not _frozen else 0.0)


## Shows the running / jumping / standing frame for the size currently being flashed.
func _draw_flicker(input_dir: float) -> void:
	var v := player.velocity if not _frozen else Vector2.ZERO
	player.animated_sprite_2d.trigger_animation(v, input_dir, _show_mode)


func _finish(new_mode: PlayerUpdated.PlayerMode, is_damage: bool) -> void:
	player.set_mode(new_mode)
	if _frozen:
		player.velocity = _saved_velocity     # carry on exactly as before the pause
	if is_damage:
		player.start_iframes()
	if player.is_on_floor():
		player.update_collision_shapes(false)
		machine.transition_to(&"Ground")
	else:
		machine.transition_to(&"Air")


func exit() -> void:
	if _tween and _tween.is_valid():
		_tween.kill()
