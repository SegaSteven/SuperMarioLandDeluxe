@tool
extends CamArea

class_name MainCamArea
## The level's main camera area (red outline) - the camera works like it always has inside it,
## scrolling left and right. Put ONE in each level and drag its edges to where the camera should
## stop: it sets the camera's limits, so you don't need to type them on the Camera2D any more.
##
## SECRETS - add SkyCamArea (blue) boxes above it and CaveCamArea (green) boxes below it:
##   - Walking past them does nothing, so they stay secret.
##   - Overlap the blue / green box over the main box's top / bottom edge a little (~16 px).
##   - When Mario, going up, gets within Switch Margin pixels (3) of the main camera's TOP edge
##     while touching a blue box, the camera switches to it: it glides fully up, so he's at the
##     bottom of the screen, and stays put (blocked off at the box's sides).
##   - The same going down at the BOTTOM edge touching a green box: it glides fully down, so
##     he's at the top.
##   - Coming back works the same way the other direction: falling within 3 pixels of the blue
##     box's bottom edge (or going up within 3 of the green box's top), or leaving the side of
##     the box, glides back to normal.
##   - A box taller than a screen: within 3 pixels of that screen's edge moves it on a step.
##
## FALLING (the death line): falling off the bottom of this red box loses a life, like the
## original game - unless Mario is over a green box, then the line is at the bottom of the green
## box instead. Blue boxes have none: falling there just drops him back into the main area.
## DeathBoxes still work too (for pits that aren't at the very bottom).

## Mario switches to a blue / green box when his sprite is within this many pixels of the main
## camera's top / bottom edge AND touching that box (so make the blue / green box overlap the
## main box's edge - about 16 pixels).
@export_range(0.0, 16.0, 1.0) var switch_margin: float = 3.0
## Seconds the camera takes to glide between areas - smaller is faster (0 = jump straight
## there). It moves in a straight line - diagonally if it needs to - easing in and out, and
## Mario always stays on screen while it moves, at any speed.
@export_range(0.0, 3.0, 0.05) var move_time: float = 0.6
## Falling off the bottom of the main area (or a green box) loses a life.
@export var death_line: bool = true

const KEYS := ["limit_left", "limit_right", "limit_top", "limit_bottom"]

## The area the camera is in right now (this one, or a sky / cave box).
var current: CamArea
var _cam: Camera2D
var _drag_v: bool = true
var _drag_h: bool = true
var _smooth: bool = true


func edge_color() -> Color:
	return Color(1.0, 0.2, 0.15)


func _ready() -> void:
	super._ready()
	if Engine.is_editor_hint():
		set_physics_process(false)
		return
	current = self
	_setup.call_deferred()


func _setup() -> void:
	_cam = get_viewport().get_camera_2d()
	if _cam == null:
		return
	_drag_v = _cam.drag_vertical_enabled
	_drag_h = _cam.drag_horizontal_enabled
	_smooth = _cam.position_smoothing_enabled
	_set_limits(area_rect())
	# Starting (e.g. at a checkpoint) up in a sky / down in a cave area: go straight there
	var m := _mario()
	if m:
		var body := _mario_rect(m)
		var main := area_rect()
		if body.end.y < main.position.y:
			var a := _area_at(m.global_position.x, true)
			if a:
				_switch(a, -1, true)
		elif body.position.y > main.end.y:
			var c := _area_at(m.global_position.x, false)
			if c:
				_switch(c, 1, true)


func _mario() -> PlayerUpdated:
	var m := GameManager.player as PlayerUpdated
	if m == null or not is_instance_valid(m) or not m.is_inside_tree() or m.is_dead:
		return null
	return m


func _physics_process(_delta: float) -> void:
	if _cam == null or not is_instance_valid(_cam):
		return
	var m := _mario()
	if _cam.has_meta("cam_locked"):
		# A boss arena or a cutscene has the camera: no switching areas. The death line still
		# works unless the cutscene has turned it off (no_death_line).
		if m and death_line and not _cam.has_meta("no_death_line") and _mario_rect(m).position.y > _death_y(m.global_position.x):
			m.die(true)
		return
	if m == null:
		return
	var state: StringName = m.state_machine.state.name if m.state_machine and m.state_machine.state else &""
	if state in [&"Pipe", &"PipeExit", &"Hidden", &"Dead"]:
		return
	var body := _mario_rect(m)
	var cx := m.global_position.x
	var main := area_rect()

	if current == self:
		# Within Switch Margin of the main camera's top / bottom edge AND touching a blue / green box
		if body.position.y < main.position.y + switch_margin and m.velocity.y <= 0.0:
			var sky := _area_touching(body, true)
			if sky:
				_switch(sky, -1)
		if current == self and body.end.y > main.end.y - switch_margin and m.velocity.y >= 0.0:
			var cave := _area_touching(body, false)
			if cave:
				_switch(cave, 1)
	elif not is_instance_valid(current):
		_switch(self, 0)
	else:
		var r := current.area_rect()
		var leaving := not r.intersects(body)
		if current is SkyCamArea and m.velocity.y > 0.0 and body.end.y > r.end.y - switch_margin:
			leaving = true                           # falling back down out of the sky box
		elif current is CaveCamArea and m.velocity.y < 0.0 and body.position.y < r.position.y + switch_margin:
			leaving = true                           # going back up out of the cave box
		if leaving:
			# Not touching the box any more: into a neighbouring box of the same kind, or back
			# to the main area
			var going_up := current is SkyCamArea
			var next := _area_touching(body, going_up)
			if next:
				_switch(next, -1 if going_up else 1)
			else:
				_switch(self, 0)
		elif not _sliding():
			# A box taller than one screen: near the edge of this screen -> move on another step
			var y: float = _cam.get_meta("cam_area_y", _cam.get_screen_center_position().y)
			var half_h := _half_height()
			if body.position.y < y - half_h + switch_margin and r.position.y < y - half_h - 1.0:
				_glide(r, _step_y(r, body, -1), false)
			elif body.end.y > y + half_h - switch_margin and r.end.y > y + half_h + 1.0:
				_glide(r, _step_y(r, body, 1), false)

	if death_line and body.position.y > _death_y(cx):
		m.die(true)


## Where falling loses a life at this x: the bottom of the main area, or of a green box below.
func _death_y(cx: float) -> float:
	var cave := _area_at(cx, false)
	if cave:
		return cave.area_rect().end.y if (cave as CaveCamArea).death_at_bottom else INF
	return area_rect().end.y


## The sky (up = true) or cave box Mario's sprite is touching.
func _area_touching(body: Rect2, up: bool) -> CamArea:
	for a in get_tree().get_nodes_in_group("cam_areas"):
		if a == self or not is_instance_valid(a):
			continue
		if ((up and a is SkyCamArea) or (not up and a is CaveCamArea)) and (a as CamArea).area_rect().intersects(body):
			return a
	return null


## The sky (up = true) or cave box whose left / right edges Mario is between.
func _area_at(cx: float, up: bool) -> CamArea:
	for a in get_tree().get_nodes_in_group("cam_areas"):
		if a == self or not is_instance_valid(a):
			continue
		if (up and a is SkyCamArea) or (not up and a is CaveCamArea):
			var r: Rect2 = (a as CamArea).area_rect()
			if cx >= r.position.x and cx <= r.end.x:
				return a
	return null


func _switch(to: CamArea, dir: int, instant: bool = false) -> void:
	current = to
	var r := to.area_rect()
	var m := _mario()
	var ty: float
	if to == self:
		var half_h := _half_height()
		ty = clampf(m.global_position.y if m else r.get_center().y,
			r.position.y + half_h, maxf(r.end.y - half_h, r.position.y + half_h))
	else:
		ty = _step_y(r, _mario_rect(m) if m else Rect2(), dir)
	if instant or move_time <= 0.0:
		_set_limits(r)
		_finish_move(ty, to == self)
		_cam.reset_smoothing()
		return
	_glide(r, ty, to == self)


## Moves the camera in a straight line (diagonally if it needs to) from where it is to its spot
## in the new area, easing in and out. The area's edges only apply once it gets there.
func _glide(r: Rect2, ty: float, back_to_normal: bool) -> void:
	var old: Tween = _cam.get_meta("cam_area_glide", null)
	if old and old.is_valid():
		old.kill()
	var from := _cam.get_screen_center_position()
	_cam.position_smoothing_enabled = false
	_cam.drag_vertical_enabled = false
	_cam.drag_horizontal_enabled = false
	for k in KEYS:                               # no edges while it travels
		_cam.set(k, -10000000 if k in ["limit_left", "limit_top"] else 10000000)
	_cam.set_meta("cam_area_x", from.x)
	_cam.set_meta("cam_area_y", from.y)
	var tw := _cam.create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_method(func(p: float):
		var pos := _keep_mario_on_screen(Vector2(lerpf(from.x, _target_x(r), p), lerpf(from.y, ty, p)))
		_cam.set_meta("cam_area_x", pos.x)
		_cam.set_meta("cam_area_y", pos.y), 0.0, 1.0, move_time)
	_cam.set_meta("cam_area_glide", tw)
	await tw.finished
	if not is_instance_valid(_cam) or _cam.get_meta("cam_area_glide", null) != tw:
		return
	_set_limits(r)
	_finish_move(ty, back_to_normal)


## Nudges a camera position so Mario (the middle of him) is never off the screen.
func _keep_mario_on_screen(pos: Vector2) -> Vector2:
	var m := _mario()
	if m == null:
		return pos
	var half := _cam.get_viewport_rect().size * 0.5 / _cam.zoom
	var c := _mario_rect(m).get_center()
	pos.x = clampf(pos.x, c.x - half.x, c.x + half.x)
	pos.y = clampf(pos.y, c.y - half.y, c.y + half.y)
	return pos


## Where the camera should be left / right in an area: following Mario, inside its edges.
func _target_x(r: Rect2) -> float:
	var half_w := _cam.get_viewport_rect().size.x * 0.5 / _cam.zoom.x
	var m := _mario()
	var x := m.global_position.x if m else r.get_center().x
	return clampf(x, r.position.x + half_w, maxf(r.end.x - half_w, r.position.x + half_w))


## Arrived: follow Mario left / right normally again; in the main area up / down too.
func _finish_move(ty: float, back_to_normal: bool) -> void:
	if _cam.has_meta("cam_area_x"):
		_cam.remove_meta("cam_area_x")
	if back_to_normal:
		if _cam.has_meta("cam_area_y"):
			_cam.remove_meta("cam_area_y")
		_cam.drag_vertical_enabled = _drag_v
	else:
		_cam.set_meta("cam_area_y", ty)
		_cam.drag_vertical_enabled = false
	_cam.drag_horizontal_enabled = _drag_h
	_cam.position_smoothing_enabled = _smooth
	_cam.reset_smoothing()


## Camera height for a full move: up (-1) = Mario at the bottom of the screen, down (1) = at
## the top. Never past the box.
func _step_y(r: Rect2, body: Rect2, dir: int) -> float:
	var half_h := _half_height()
	var y := (body.end.y - half_h) if dir < 0 else (body.position.y + half_h)
	return clampf(y, r.position.y + half_h, maxf(r.end.y - half_h, r.position.y + half_h))


func _sliding() -> bool:
	var tw: Tween = _cam.get_meta("cam_area_glide", null)
	return tw != null and tw.is_valid() and tw.is_running()


func _half_height() -> float:
	return _cam.get_viewport_rect().size.y * 0.5 / _cam.zoom.y


## Puts the camera's edges on a box.
func _set_limits(r: Rect2) -> void:
	_cam.limit_left = int(r.position.x)
	_cam.limit_right = int(r.end.x)
	_cam.limit_top = int(r.position.y)
	_cam.limit_bottom = int(r.end.y)


## Mario's sprite (his current frame).
func _mario_rect(m: PlayerUpdated) -> Rect2:
	var spr: AnimatedSprite2D = m.animated_sprite_2d
	var size := Vector2(16, 16)
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation(spr.animation):
		var tex := spr.sprite_frames.get_frame_texture(spr.animation, spr.frame)
		if tex:
			size = tex.get_size() * spr.global_scale.abs()
	var centre := (spr.global_position + spr.offset) if spr else m.global_position
	return Rect2(centre - size * 0.5, size)
