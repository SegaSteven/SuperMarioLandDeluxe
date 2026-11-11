@tool
extends CamArea

class_name BossCamArea
## A boss arena (orange outline). Draw it around the part Mario is kept in, inside the level's
## MainCamArea. It can be narrower than a screen: the camera then shows it against the main
## area's edge (e.g. at the end of the level), and the walls go at the box's own edges.
## When Mario gets Lock After pixels into it, the camera slides over to it and LOCKS there,
## and invisible walls go up at its edges so Mario can't leave the arena (like the original:
## the screen stops and there's no going back). Falling into lava / off the bottom still loses
## a life as normal. The FakeDaisy cutscene takes the camera over from here when the boss
## switch is pressed (Mario walks through the walls then).

## How far into the box (pixels) Mario has to get before it locks - he must be standing on
## something then too, so it never locks mid-jump over a pit.
@export var lock_after: float = 24.0
## Seconds the camera takes to slide into place when it locks (0 = straight away).
@export var lock_time: float = 0.4
## Wall at the left edge (Mario can't go back).
@export var wall_left: bool = true
## Wall at the right edge too.
@export var wall_right: bool = true
## Optional boss music that starts when it locks (replaces the level music).
@export var boss_music: AudioStream

signal locked

var is_locked: bool = false
var _walls: Array[StaticBody2D] = []


func edge_color() -> Color:
	return Color(1.0, 0.55, 0.1)


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		set_physics_process(false)


func _physics_process(_delta: float) -> void:
	if is_locked:
		return
	var m := GameManager.player as PlayerUpdated
	if m == null or not is_instance_valid(m) or m.is_dead or not m.is_inside_tree():
		return
	var r := area_rect()
	var x := m.global_position.x
	if m.is_on_floor() and x >= r.position.x + lock_after and x <= r.end.x and m.global_position.y >= r.position.y and m.global_position.y <= r.end.y + 16.0:
		lock()


## Locks the camera on the arena and puts the walls up (also callable from a level script).
func lock() -> void:
	if is_locked:
		return
	is_locked = true
	var r := area_rect()
	var cam := get_viewport().get_camera_2d()
	if cam:
		var half := cam.get_viewport_rect().size * 0.5 / cam.zoom
		# Centred on the box; a box narrower / shorter than the screen is shown inside the
		# camera's current edges (the MainCamArea) - e.g. right up against the end of the level
		var to := r.get_center()
		to.x = clampf(to.x, cam.limit_left + half.x, maxf(cam.limit_right - half.x, cam.limit_left + half.x))
		to.y = clampf(to.y, cam.limit_top + half.y, maxf(cam.limit_bottom - half.y, cam.limit_top + half.y))
		var from := cam.get_screen_center_position()
		cam.set_meta("cam_locked", true)               # the MainCamArea stops switching areas
		cam.position_smoothing_enabled = false
		cam.drag_horizontal_enabled = false
		cam.drag_vertical_enabled = false
		cam.set_meta("cam_area_x", from.x)
		cam.set_meta("cam_area_y", from.y)
		var view := Rect2(to - half, half * 2.0)
		# Edges open wide enough for the slide, then on the arena
		cam.limit_left = int(floor(minf(from.x - half.x, view.position.x)))
		cam.limit_right = int(ceil(maxf(from.x + half.x, view.end.x)))
		if lock_time > 0.0:
			var tw := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
			tw.tween_method(func(p: float):
				cam.set_meta("cam_area_x", lerpf(from.x, to.x, p))
				cam.set_meta("cam_area_y", lerpf(from.y, to.y, p)), 0.0, 1.0, lock_time)
		else:
			cam.set_meta("cam_area_x", to.x)
			cam.set_meta("cam_area_y", to.y)
		_set_limits_later(cam, view, lock_time)
	if wall_left:
		_add_wall(r.position.x - 4.0, r)
	if wall_right:
		_add_wall(r.end.x + 4.0, r)
	if boss_music:
		var lm := get_tree().current_scene.get_node_or_null("LevelMusic") as AudioStreamPlayer
		if lm:
			lm.stream = boss_music
			lm.play()
	locked.emit()


func _set_limits_later(cam: Camera2D, view: Rect2, t: float) -> void:
	if t > 0.0:
		await get_tree().create_timer(t).timeout
	if not is_instance_valid(cam):
		return
	cam.set_meta("cam_area_x", view.get_center().x)
	cam.set_meta("cam_area_y", view.get_center().y)
	cam.limit_left = int(floor(view.position.x))
	cam.limit_right = int(ceil(view.end.x))
	cam.limit_top = int(floor(view.position.y))
	cam.limit_bottom = int(ceil(view.end.y))


## An invisible wall, the height of the box (and a screen above it so he can't jump over).
func _add_wall(x: float, r: Rect2) -> void:
	var body := StaticBody2D.new()
	body.collision_layer = Layers.bit(Layers.GROUND)
	body.collision_mask = 0
	var cs := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(8.0, r.size.y + 288.0)
	cs.shape = shape
	body.add_child(cs)
	get_tree().current_scene.add_child(body)
	body.global_position = Vector2(x, r.get_center().y - 144.0)
	_walls.append(body)


## Takes the walls down again (e.g. after the boss, if Mario should be free to walk on).
func unlock_walls() -> void:
	for w in _walls:
		if is_instance_valid(w):
			w.queue_free()
	_walls.clear()
