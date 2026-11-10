extends Node2D

class_name LoadRoomBoat
## Mario's speedboat in the load room intro.
## YOUR ART - two pictures, same size, front pointing RIGHT:
##   Sprite Moving   the boat with the wave/spray behind it (shown while it's moving)
##   Sprite Stopped  the boat on its own (shown once it's stopped at the dock)
## They start as Assets/Sprites/LoadRoom/Speedboat_moving.png and Speedboat_stopped.png -
## draw over those, or pick your own. Sprite Origin is the pixel in the picture that sits on
## this node's position (the waterline under the middle of the boat).
## (Or add your own children instead: "Body" (Sprite2D or AnimatedSprite2D) is shown while
## the boat is moving, and "BodyStopped" (if there is one) is shown instead once it stops.)
## With no pictures at all, a placeholder boat is drawn.
## Deck Offset is where Mario stands (his feet), relative to this node.
## Sounds: the engine (Assets/SFX/boat_engine.wav) loops while it moves and the splash
## (boat_stop.wav) plays as it stops - swap them under Sound.

@export var sprite_moving: Texture2D:
	set(v):
		sprite_moving = v
		queue_redraw()
@export var sprite_stopped: Texture2D:
	set(v):
		sprite_stopped = v
		queue_redraw()
@export var sprite_origin: Vector2 = Vector2(40, 13)
## Faster than this (pixels per second) counts as moving.
@export var moving_speed: float = 15.0
@export var deck_offset: Vector2 = Vector2(-2, -5)

@export_group("Sound")
## Loops while the boat is moving; higher pitch when it's fast. Empty = silent.
@export var engine_sound: AudioStream = preload("res://Assets/SFX/boat_engine.wav")
@export var engine_volume_db: float = 0.0
@export var engine_pitch_slow: float = 0.75
@export var engine_pitch_fast: float = 1.35
## Plays once when it stops (the splash as it pulls up at the dock). Empty = none.
@export var stop_sound: AudioStream = preload("res://Assets/SFX/boat_stop.wav")
@export_group("")
@export var bob_height: float = 0.75         ## bobbing on the water when stopped
@export var bob_speed: float = 4.0
@export var spray_on: bool = true

var _t: float = 0.0
var bob: float = 0.0
var speed: float = 0.0                       # pixels per second (worked out from movement)
var _last_x: float = 0.0
var _engine: AudioStreamPlayer
var _was_moving: bool = false


func _ready() -> void:
	_last_x = position.x
	if Engine.is_editor_hint():
		return
	if engine_sound:
		_engine = AudioStreamPlayer.new()
		_engine.name = "EngineSound"
		var st: AudioStream = engine_sound
		if st is AudioStreamWAV:                     # make sure it loops
			var w := (st as AudioStreamWAV).duplicate() as AudioStreamWAV
			w.loop_mode = AudioStreamWAV.LOOP_FORWARD
			w.loop_begin = 0
			w.loop_end = int(w.get_length() * w.mix_rate)
			st = w
		_engine.stream = st
		_engine.volume_db = -80.0
		add_child(_engine)


func _process(delta: float) -> void:
	_t += delta
	speed = (position.x - _last_x) / maxf(delta, 0.0001)
	_last_x = position.x
	# bobs when slow, skims flat (nose a little up) when fast
	var fast := clampf(absf(speed) / 200.0, 0.0, 1.0)
	bob = sin(_t * bob_speed) * bob_height * (1.0 - fast)
	var body := get_node_or_null("Body") as Node2D
	var stopped_body := get_node_or_null("BodyStopped") as Node2D
	var moving := is_moving()
	if body:
		body.position.y = bob
		body.rotation = -0.06 * fast
		if stopped_body:
			body.visible = moving
	if stopped_body:
		stopped_body.position.y = bob
		stopped_body.visible = not moving or body == null
	var spray := get_node_or_null("Spray") as CanvasItem
	if spray:
		spray.visible = fast > 0.1
	_update_sound(delta, fast)
	queue_redraw()


func _update_sound(delta: float, fast: float) -> void:
	var moving := is_moving()
	if _engine:
		if moving and not _engine.playing:
			_engine.play()
		var target := engine_volume_db if moving else -60.0
		_engine.volume_db = move_toward(_engine.volume_db, target, delta * (240.0 if moving else 90.0))
		_engine.pitch_scale = lerpf(engine_pitch_slow, engine_pitch_fast, fast)
		if not moving and _engine.playing and _engine.volume_db <= -59.0:
			_engine.stop()
	if _was_moving and not moving and stop_sound:
		var p := AudioStreamPlayer.new()
		p.stream = stop_sound
		add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	_was_moving = moving


## Where Mario's feet go on the deck, in the room.
func deck_position() -> Vector2:
	return global_position + deck_offset + Vector2(0, bob)


func is_moving() -> bool:
	return absf(speed) > moving_speed


func _draw() -> void:
	var fast := clampf(absf(speed) / 200.0, 0.0, 1.0)
	if get_node_or_null("Body") == null and (sprite_moving or sprite_stopped):
		var tex := sprite_moving if is_moving() and sprite_moving else sprite_stopped
		if tex == null:
			tex = sprite_moving
		draw_set_transform(Vector2(0, bob), -0.04 * fast, Vector2.ONE)
		draw_texture(tex, -sprite_origin)
		return
	# spray / wake behind the boat while it's moving
	if spray_on and fast > 0.1 and get_node_or_null("Spray") == null:
		for i in 4:
			var x := -22.0 - i * 6.0 - fmod(_t * 60.0, 6.0)
			var h := (3.0 - i * 0.6) * fast
			draw_line(Vector2(x, 1), Vector2(x - 5, 1 - h), Color(1, 1, 1, 0.8 - i * 0.18), 1.0)
		draw_line(Vector2(-40 * fast - 20, 2), Vector2(-20, 2), Color(1, 1, 1, 0.7), 1.0)
	if get_node_or_null("Body") != null:
		return
	draw_set_transform(Vector2(0, bob), -0.06 * fast, Vector2.ONE)
	# hull: low, long, pointed at the front
	draw_colored_polygon(PackedVector2Array([Vector2(-20, -5), Vector2(14, -5), Vector2(24, -2), Vector2(16, 2), Vector2(-18, 2)]), Color(0.92, 0.92, 0.95))
	draw_colored_polygon(PackedVector2Array([Vector2(-19, -1), Vector2(19, -1), Vector2(16, 2), Vector2(-18, 2)]), Color(0.85, 0.12, 0.12))   # stripe
	# windscreen + seat
	draw_colored_polygon(PackedVector2Array([Vector2(4, -5), Vector2(8, -10), Vector2(10, -10), Vector2(8, -5)]), Color(0.55, 0.85, 1.0, 0.9))
	draw_rect(Rect2(-14, -8, 6, 3), Color(0.25, 0.25, 0.3))
	# outboard motor at the back
	draw_rect(Rect2(-23, -8, 3, 9), Color(0.2, 0.2, 0.22))
