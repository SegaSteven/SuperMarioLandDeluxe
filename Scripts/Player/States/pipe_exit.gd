extends PlayerState
## Coming OUT of a pipe after going through one - the opposite of the Pipe state.
## Mario waits (hidden inside the pipe) until the screen fade has finished, then slides out
## the same distance and at the same speed he slid in, and carries on playing.
## The level starts this by itself when Mario arrives through a pipe (see basic_level.gd):
##   machine.transition_to(&"PipeExit", {"direction": Vector2.UP})
## Which way he comes out is set on the pipe he went INTO (Exit Animation in the Inspector).
## Auto = up out of the pipe if he arrives standing on a pipe (a pipe node or pipe tiles),
## otherwise no animation (dropping into a room, or landing on a platform like a Fallwait Block).

## Same as the Pipe state, so going in and coming out match.
@export var slide_time: float = 1.0
@export var slide_distance: float = 16.0
## Nudges where Mario comes out (and ends up), e.g. (4, 0) = 4 pixels to the right.
@export var exit_offset: Vector2 = Vector2(4, 0)

var _target: Vector2 = Vector2.ZERO
var _dir: Vector2
var _layer: int
var _mask: int


func _init() -> void:
	allows_contacts = false
	allows_damage = false
	allows_stomp = false
	allows_transform = false


## Mario gets to land (hidden) while the screen is still covered, plus at least this many
## frames. If he still hasn't landed he arrived in mid-air (dropping into a room) and with Auto
## he just carries on falling.
@export var settle_frames: int = 8

var _auto: bool = false
var _settling: bool = false
var _frames: int = 0


func enter(msg: Dictionary) -> void:
	_dir = msg.get("direction", Vector2.UP)
	_auto = msg.get("auto", false)
	player.velocity = Vector2.ZERO
	_layer = player.collision_layer
	_mask = player.collision_mask
	player.visible = false
	_frames = 0
	_settling = false
	_lift_out_of_solids.call_deferred()


## If Destination Spawn is inside a pipe (or anything solid), lift Mario up to the top of it
## first, so he stands on the pipe and comes out of it instead of getting stuck inside.
func _lift_out_of_solids() -> void:
	await get_tree().physics_frame          # the level's collision is ready after a physics frame
	if not _is_current():
		return
	var cs: CollisionShape2D = player.body_collision_shape
	if cs and cs.shape:
		var space := player.get_world_2d().direct_space_state
		var q := PhysicsShapeQueryParameters2D.new()
		q.shape = cs.shape
		q.collision_mask = player.collision_mask
		q.exclude = [player.get_rid()]
		for i in 64:
			q.transform = cs.global_transform
			if space.intersect_shape(q, 1).is_empty():
				break
			player.global_position.y -= 1.0
	_settling = true


func physics_update(delta: float) -> void:
	if not _settling:
		player.velocity = Vector2.ZERO
		return
	# Hidden behind the fade: let him drop onto whatever he arrived on
	player.apply_gravity(delta)
	player.move_and_slide()
	_frames += 1
	if player.is_on_floor():
		_settling = false
		_target = player.global_position
		if _auto and not _on_pipe():
			_finish()                         # landed on a platform (e.g. a Fallwait Block), not a pipe
		else:
			_slide_out()
	elif _frames >= settle_frames and (not SceneManager.is_transitioning or _frames >= 90):
		_settling = false
		_target = player.global_position
		if _auto:
			_finish()                         # mid-air arrival: no pipe here, just fall
		else:
			_slide_out()


func _slide_out() -> void:
	player.velocity = Vector2.ZERO
	_target += exit_offset
	player.collision_layer = 0
	player.collision_mask = 0
	var mouth := _mouth()
	player.global_position = _target - _dir * slide_distance
	_pose()
	while SceneManager.is_transitioning:    # wait for the screen fade to finish
		await get_tree().process_frame
		if not _is_current():
			return
	# Mario stays hidden; a copy of him is drawn inside a mask that only covers the outside of
	# the pipe, so the part still inside the pipe is cut off (works with tile pipes and keeps
	# his palette / draw order).
	var mask := _make_mask(mouth)
	var ghost := _make_ghost(mask)
	var tw := player.create_tween()
	tw.tween_property(player, "global_position", _target, slide_time)
	while tw.is_running():
		_follow(ghost)
		await get_tree().process_frame
		if not _is_current():
			mask.queue_free()
			return
	mask.queue_free()
	if _is_current():
		_finish()


## Where the pipe's opening is: the edge of Mario's body on the side he comes out of, measured
## where he ends up (for Up that's his feet = the top of the pipe).
func _mouth() -> Vector2:
	var cs: CollisionShape2D = player.body_collision_shape
	var r := Rect2(-4, -8, 8, 16)
	if cs and cs.shape:
		r = cs.shape.get_rect()
	var off := (cs.global_position - player.global_position) if cs else Vector2.ZERO
	var centre := _target + off + r.get_center()
	return centre - Vector2(_dir.x * r.size.x, _dir.y * r.size.y) * 0.5


func _make_mask(mouth: Vector2) -> Polygon2D:
	var mask := Polygon2D.new()
	mask.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	mask.z_index = player.z_index
	mask.z_as_relative = player.z_as_relative
	var side := Vector2(-_dir.y, _dir.x) * 64.0
	var far := _dir * 64.0
	mask.polygon = PackedVector2Array([mouth - side, mouth + side, mouth + side + far, mouth - side + far])
	player.get_parent().add_child(mask)
	return mask


func _make_ghost(mask: Node) -> AnimatedSprite2D:
	var src: AnimatedSprite2D = player.animated_sprite_2d
	var g := AnimatedSprite2D.new()
	g.sprite_frames = src.sprite_frames
	g.animation = src.animation
	g.frame = src.frame
	g.flip_h = src.flip_h
	g.offset = src.offset
	g.centered = src.centered
	g.material = src.material
	g.modulate = src.modulate * player.modulate
	g.use_parent_material = false
	if src.is_playing():
		g.play(src.animation)
		g.frame = src.frame
	mask.add_child(g)
	_follow(g)
	return g


func _follow(g: AnimatedSprite2D) -> void:
	g.global_transform = player.animated_sprite_2d.global_transform


## Auto only rises out of pipes: a pipe node or the level's tiles (pipes drawn as tiles).
func _on_pipe() -> bool:
	for i in player.get_slide_collision_count():
		var c := player.get_slide_collision(i)
		if c.get_normal().y < -0.5:
			var o := c.get_collider()
			if o is PipeD1 or o is PipeD2 or o is PipeSide or o is ParanhaPlantPipe or o is TileMap or o is TileMapLayer:
				return true
	return false


func _pose() -> void:
	var walk_dir := signf(_dir.x)
	player.animated_sprite_2d.trigger_animation(Vector2(walk_dir * 40.0, 0.0) if walk_dir != 0.0 else Vector2.ZERO,
		walk_dir, player.player_mode)


func _is_current() -> bool:
	return is_instance_valid(player) and machine.state == self


func _finish() -> void:
	player.collision_layer = _layer
	player.collision_mask = _mask
	player.visible = true
	player.global_position = _target
	machine.transition_to(&"Ground" if player.is_on_floor() else &"Air")


func exit() -> void:
	player.visible = true
	if player.collision_layer == 0:
		player.collision_layer = _layer
		player.collision_mask = _mask
