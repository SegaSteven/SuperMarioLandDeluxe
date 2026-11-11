extends Enemy

class_name BunBun
## Bunbun: flies in a straight line. When it's over Mario it stops, drops a spear, then flies on.
## Mario can jump on it: he bounces off and it shows the "dead" frame for Dead Time seconds,
## slowly sinking Dead Drop pixels with no collision. Then it flips upside down, hops up
## Arc Height pixels while moving Arc Distance pixels to the left (back to the height it
## started the hop at), and keeps falling until it's off the bottom of the screen.

@export var fly_speed: float = 60.0
@export var drop_range: float = 6.0           ## how close (sideways) Mario must be to trigger a drop
@export var pause_before_drop: float = 0.5    ## stops this long before dropping the spear
@export var pause_after_drop: float = 0.5     ## and this long after, then flies on
@export var drop_cooldown: float = 2.0
@export var spawned_scene: PackedScene        ## the thing it drops (arrow_drop.tscn)

@export_group("Stomped")
@export var dead_time: float = 0.5            ## seconds the dead frame shows
@export var dead_drop: float = 4.0            ## pixels it sinks during that time
@export var arc_height: float = 8.0           ## then it flips over and hops up this many pixels
@export var arc_distance: float = 16.0        ## ...landing back at the same height this far over
@export var arc_time: float = 0.4             ## seconds the hop takes (up and back down)
@export var arc_direction: int = -1           ## -1 = to the left, 1 = to the right
@export var arc_sound: AudioStream = preload("res://Assets/SFX/enemydie2.wav")  ## plays as the hop starts

var _tumbling: bool = false
var _tumble_gravity: float = 0.0
var _pause_left: float = 0.0
var _cooldown_left: float = 0.0
var _drop_pending: bool = false


func _init() -> void:
	score = 800   # default; the Inspector can still change it


func _on_ready() -> void:
	_play_anim("fly")


func _alive_physics(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	if _pause_left > 0.0:                       # stopped over Mario
		_pause_left -= delta
		if _pause_left <= 0.0 and _drop_pending:
			_drop_pending = false
			_drop()
			_pause_left = pause_after_drop
		return

	global_position.x += direction * fly_speed * delta    # straight line, same height

	var p := get_player()
	if p and _cooldown_left <= 0.0 and spawned_scene != null:
		var below := p.global_position.y > global_position.y
		if below and absf(p.global_position.x - global_position.x) <= drop_range:
			_pause_left = pause_before_drop
			_drop_pending = true
			_cooldown_left = drop_cooldown


func _drop() -> void:
	var spear = spawned_scene.instantiate()
	spear.global_position = global_position + Vector2(0, 4)
	get_tree().current_scene.add_child(spear)


## Jumped on: Mario bounces off, the dead frame shows while it sinks a little, then it flips
## over, hops up and to the left and falls off the screen.
func stomp(_player: Node) -> void:
	if is_dead:
		return
	_begin_death()
	velocity = Vector2.ZERO
	collision_layer = 0
	collision_mask = 0
	if body_shape:
		body_shape.set_deferred("disabled", true)
	for a in find_children("*", "Area2D", true, false):
		(a as Area2D).set_deferred("monitoring", false)
		(a as Area2D).set_deferred("monitorable", false)
	_play_anim("dead")
	_play_sfx("Enemykilled")
	award_score()
	var tw := create_tween()
	tw.tween_property(self, "position:y", position.y + dead_drop, dead_time)
	tw.tween_callback(_start_tumble)


## Upside down, then a hop: up Arc Height and over Arc Distance, then it keeps falling.
func _start_tumble() -> void:
	if sprite:
		sprite.flip_v = true
	var half := maxf(arc_time, 0.05) * 0.5
	_tumble_gravity = 2.0 * arc_height / (half * half)
	velocity = Vector2(signi(arc_direction) * arc_distance / (half * 2.0), -_tumble_gravity * half)
	_tumbling = true
	if arc_sound:
		# Played from the level, so it isn't cut off when the Bunbun falls off screen
		var sfx := AudioStreamPlayer.new()
		sfx.stream = arc_sound
		sfx.bus = "SFX" if AudioServer.get_bus_index("SFX") >= 0 else "Master"
		var host: Node = get_tree().current_scene if get_tree().current_scene else get_parent()
		host.add_child(sfx)
		sfx.play()
		sfx.finished.connect(sfx.queue_free)


func _dead_physics(delta: float) -> void:
	if _tumbling:
		velocity.y += _tumble_gravity * delta
		position += velocity * delta
		var cam := get_viewport().get_camera_2d()
		var bottom := (cam.get_screen_center_position().y + 90.0) if cam else 400.0
		if global_position.y > bottom + 16.0:
			queue_free()
	elif sprite and sprite.flip_v:              # knocked out by a superball / star: tumbles
		velocity.y += gravity * delta
		position += velocity * delta
