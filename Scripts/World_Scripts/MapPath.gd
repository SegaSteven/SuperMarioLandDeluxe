extends Path2D

class_name MapPath
## A walkable route between two MapNodes. Add it as a CHILD of the MapNode it starts at.
##
## HOW TO USE (in the editor):
##   1. Select a MapNode, Add Child Node > MapPath.
##   2. Set "Target" to the MapNode this path leads to, and "Direction" to the d-pad
##      direction that starts the walk.
##   3. Click the path and use the toolbar's "Add Point" tool to draw the route Mario walks
##      on the map. Start at (0,0) (the MapNode itself). No points at all = straight line.
##   4. Done - Mario can also walk it backwards (target -> start) automatically.
##
## OPTIONAL "ANIMATION" CONTROLS:
##   Point Animations: one entry per curve point. Entry N is the Mario animation used while
##   walking from point N-1 to point N ("Up", "Down", "Left", "Right", "Water_Up", ...).
##   Leave an entry empty and it's picked automatically from the direction of travel.
##   Play Animation: runs an AnimationPlayer animation when Mario starts the walk
##   (a bridge appearing, a gate opening, etc).

enum Dir { UP, DOWN, LEFT, RIGHT }
enum ReverseDir { AUTO, UP, DOWN, LEFT, RIGHT }

@export_node_path("Node2D") var target: NodePath
@export var direction: Dir = Dir.UP
@export var bidirectional: bool = true
@export var reverse_direction: ReverseDir = ReverseDir.AUTO

@export_group("Walking")
@export var speed: float = 40.0                       ## pixels per second
@export var smooth: bool = false                      ## follow the bezier curve instead of straight segments
@export var point_animations: PackedStringArray = PackedStringArray()
@export var all_water: bool = false                   ## use the "Water_..." animations for the whole path

@export_group("Locking")
@export var require_source_beaten: bool = false       ## can only walk forward once the level you start at is beaten
@export var required_level: String = ""               ## e.g. "1-2": that level must be beaten first

@export_group("Secret / unlock")
@export var required_unlock: String = ""              ## e.g. "star_road_1": blocked AND hidden until a door unlocks it
@export var hidden_until_unlocked: bool = true        ## untick to show it (but keep it blocked) before it's unlocked
@export var reveal_nodes: Array[NodePath] = []        ## things to show when it unlocks: a TileMap layer of path tiles, a bridge...
@export var draw_dots: bool = false                   ## draw the route as dots in-game (handy if you haven't painted path tiles)
@export var dot_spacing: float = 8.0
@export var dot_color: Color = Color(0.95, 0.85, 0.3)
@export var reveal_time: float = 1.5                  ## seconds the dot-by-dot reveal takes

@export_group("Trigger")
@export_node_path("AnimationPlayer") var animation_player: NodePath
@export var play_animation: StringName = &""


var _dots: PackedVector2Array = PackedVector2Array()
var _dots_shown: int = 0


func _enter_tree() -> void:
	add_to_group("map_paths")


func _ready() -> void:
	_build_dots()
	var shown := not is_hidden()
	_dots_shown = _dots.size() if shown else 0
	for path in reveal_nodes:
		var n := get_node_or_null(path) as CanvasItem
		if n:
			n.visible = shown
	queue_redraw()


## Locked and supposed to stay out of sight?
func is_hidden() -> bool:
	return required_unlock != "" and hidden_until_unlocked and not OverworldMan.is_unlocked(required_unlock)


## True when this path's unlock was just earned and it hasn't played its reveal yet.
func wants_reveal() -> bool:
	return required_unlock != "" and OverworldMan.pending_reveals.has(required_unlock) and OverworldMan.is_unlocked(required_unlock)


## Plays the Super Mario World style reveal: dots appear along the route one by one,
## then the reveal nodes and the target level icon appear. Await it.
func reveal() -> void:
	_build_dots()
	_dots_shown = 0
	var tween := create_tween()
	tween.tween_method(func(v: float):
		_dots_shown = int(v)
		queue_redraw(), 0.0, float(_dots.size()), reveal_time)
	await tween.finished
	_dots_shown = _dots.size()
	for path in reveal_nodes:
		var n := get_node_or_null(path) as CanvasItem
		if n:
			n.visible = true
			n.modulate.a = 0.0
			create_tween().tween_property(n, "modulate:a", 1.0, 0.4)
	var tgt := get_target()
	if tgt is MapNode:
		tgt.refresh_visibility(true)
	queue_redraw()


func _build_dots() -> void:
	_dots.clear()
	var route := build_route(false)
	var pts: PackedVector2Array = route["points"]
	for i in range(1, pts.size()):
		var a := to_local(pts[i - 1])
		var b := to_local(pts[i])
		var steps := maxi(1, int(a.distance_to(b) / dot_spacing))
		for k in steps:
			_dots.append(a.lerp(b, float(k) / steps))
	if pts.size() > 0:
		_dots.append(to_local(pts[pts.size() - 1]))


func _draw() -> void:
	# During a reveal the dots always draw; otherwise only if draw_dots is ticked
	var revealing := _dots_shown < _dots.size()
	if not draw_dots and not revealing:
		return
	if is_hidden() and _dots_shown == 0:
		return
	for i in mini(_dots_shown, _dots.size()):
		draw_circle(_dots[i], 1.5, dot_color)


func get_source() -> Node2D:
	return get_parent() as Node2D


func get_target() -> Node2D:
	if target.is_empty():
		return null
	return get_node_or_null(target) as Node2D


func get_reverse_direction() -> int:
	match reverse_direction:
		ReverseDir.UP:
			return Dir.UP
		ReverseDir.DOWN:
			return Dir.DOWN
		ReverseDir.LEFT:
			return Dir.LEFT
		ReverseDir.RIGHT:
			return Dir.RIGHT
	match direction:   # AUTO = the opposite key
		Dir.UP:
			return Dir.DOWN
		Dir.DOWN:
			return Dir.UP
		Dir.LEFT:
			return Dir.RIGHT
	return Dir.LEFT


func is_open(walking_backwards: bool) -> bool:
	if required_unlock != "" and not OverworldMan.is_unlocked(required_unlock):
		return false   # secret paths stay shut both ways until unlocked
	if walking_backwards:
		return true
	var source := get_source() as MapNode
	if require_source_beaten and source != null and source.is_level() and not source.is_beaten():
		return false
	if required_level != "" and not OverworldMan.is_beaten(required_level):
		return false
	return true


func play_trigger_animation() -> void:
	if animation_player.is_empty() or play_animation == &"":
		return
	var player := get_node_or_null(animation_player) as AnimationPlayer
	if player and player.has_animation(play_animation):
		player.play(play_animation)


## Returns {"points": PackedVector2Array (global), "anims": PackedStringArray}.
## anims[i] is the Mario animation to use while walking from points[i-1] to points[i].
func build_route(walking_backwards: bool) -> Dictionary:
	var pts := PackedVector2Array()
	var custom := PackedStringArray()
	var water := PackedByteArray()

	if curve != null and curve.point_count > 0:
		if smooth:
			for p in curve.tessellate():
				pts.append(to_global(p))
				custom.append("")
				water.append(1 if all_water else 0)
		else:
			for i in curve.point_count:
				pts.append(to_global(curve.get_point_position(i)))
				var name_i := point_animations[i] if i < point_animations.size() else ""
				custom.append(name_i)
				water.append(1 if (all_water or name_i.begins_with("Water_")) else 0)

	# Make sure the route really starts on the source node and ends on the target node
	var src_pos := get_source().global_position
	if pts.is_empty() or pts[0].distance_to(src_pos) > 0.5:
		pts.insert(0, src_pos)
		custom.insert(0, "")
		water.insert(0, 0)
	var tgt := get_target()
	if tgt != null and pts[pts.size() - 1].distance_to(tgt.global_position) > 0.5:
		pts.append(tgt.global_position)
		custom.append("")
		water.append(1 if all_water else 0)

	var out_pts := PackedVector2Array()
	var out_anims := PackedStringArray()
	var n := pts.size() - 1

	for k in pts.size():
		var idx := (n - k) if walking_backwards else k
		out_pts.append(pts[idx])
		if k == 0:
			out_anims.append("")
			continue
		var from_p := pts[(n - k + 1) if walking_backwards else (k - 1)]
		var to_p := pts[idx]
		var leg_water := water[(n - k + 1) if walking_backwards else k] == 1
		var name_k := ""
		if not walking_backwards:
			name_k = custom[k]
		if name_k == "":
			name_k = _heading_animation(to_p - from_p, leg_water)
		out_anims.append(name_k)

	return {"points": out_pts, "anims": out_anims}


func _heading_animation(delta: Vector2, use_water: bool) -> String:
	var base := "Down"
	if absf(delta.x) >= absf(delta.y):
		base = "Right" if delta.x >= 0.0 else "Left"
	else:
		base = "Down" if delta.y >= 0.0 else "Up"
	return ("Water_" + base) if use_water else base
