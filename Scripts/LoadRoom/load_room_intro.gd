extends Node

class_name LoadRoomIntro
## The load room's opening: Mario arrives on a boat, it docks against the left edge of the room,
## and he does one smooth jump from the deck to his start position (the room's Start Position,
## landing just above the ground) while the camera pans over to the UFOs. The camera locks
## there (the boat is out of sight) and an invisible wall stops him going back.
## Press Start to skip it. Untick Play Intro to turn it off.
##
## Positions are in room pixels: the UFO screen is x 0 - 256, the sea is to the left of it.

signal finished

@export var play_intro: bool = true
@export var boat_path: NodePath = ^"../Boat"
@export var camera_path: NodePath = ^"../Camera2D"
## The CollisionShape2D used as the invisible wall (switched off until Mario has walked past).
@export var wall_path: NodePath = ^"../Walls/LeftWall"

## Wait this long before the boat sets off (lets the fade from the title screen finish).
@export var start_delay: float = 0.8

@export_group("Boat")
@export var boat_start_x: float = -260.0        ## off-screen to the left
@export var boat_dock_x: float = -24.0          ## where it stops (alongside the dock, by the room's edge)
@export var boat_time: float = 1.1              ## how long it takes to come in (a speedboat: fast, then stops sharply)
@export var boat_sound: AudioStream             ## e.g. a horn as it docks (optional)
@export var pause_after_docking: float = 0.4

@export_group("Mario")
## Where he lands (x). -1 = the load room's Start Position.
@export var land_x: float = -1.0
@export var floor_y: float = 128.0              ## the top of the floor he lands on
@export var land_above_ground: float = 3.0      ## lands this far above the floor, then drops onto it
@export var jump_height: float = 30.0
@export var jump_time: float = 0.8

@export_group("Camera")
@export var camera_start_x: float = -60.0       ## looking at the sea, the boat and the room's edge
@export var camera_end_x: float = 128.0         ## the UFO screen (where it locks)
@export var pan_time: float = 1.2               ## starts as he jumps

@export_group("")
## Button that skips the intro.
@export var skip_action: StringName = &"Start"

var playing: bool = false
var _player: PlayerUpdated
var _skip: bool = false
var _start_was_down: bool = true
var _tweens: Array[Tween] = []
var _land_x: float = 24.0
var _jump_from: Vector2
var _jump_to: Vector2


func boat() -> LoadRoomBoat: return get_node_or_null(boat_path) as LoadRoomBoat
func camera() -> Camera2D: return get_node_or_null(camera_path) as Camera2D
func wall() -> CollisionShape2D: return get_node_or_null(wall_path) as CollisionShape2D


## Starts the intro with this Mario. Await it (or the finished signal) to know when it's done.
func play(player: PlayerUpdated, start_position: Vector2 = Vector2(24, 120)) -> void:
	_player = player
	_land_x = start_position.x if land_x < 0.0 else land_x
	playing = true
	_skip = false
	_start_was_down = Input.is_action_pressed(skip_action)
	player.state_machine.transition_to(&"Scripted")
	_set_wall(false)
	if camera():
		camera().position.x = camera_start_x
	var b := boat()
	if b:
		b.position.x = boat_start_x
		b.visible = true

	_anim("idle")
	_stand_on_boat()
	await _wait(start_delay)
	if _skip:
		_finish()
		return

	# 1. The boat sails in with Mario on deck, slowing down as it docks
	var t := _tween()
	if b:
		t.tween_property(b, "position:x", boat_dock_x, boat_time).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	else:
		t.tween_interval(boat_time)
	while t.is_running() and not _skip:
		_stand_on_boat()
		await get_tree().process_frame
	if _skip:
		_finish()
		return
	if boat_sound:
		_sound(boat_sound)
	await _wait(pause_after_docking)
	if _skip:
		_finish()
		return

	# 2. One jump from the deck to his start position, while the camera pans over
	_jump_from = _player.global_position
	_jump_to = Vector2(_land_x, _y_on_floor() - land_above_ground)
	var jump_sfx := _player.get_node_or_null("Jump") as AudioStreamPlayer
	if jump_sfx:
		jump_sfx.play()
	_anim("jump")
	if camera():
		_tween().tween_property(camera(), "position:x", camera_end_x, pan_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var j := _tween()
	j.tween_method(_jump_step, 0.0, 1.0, jump_time)
	while j.is_running() and not _skip:
		await get_tree().process_frame
	if _skip:
		_finish()
		return
	# 3. Landed: he's free to move. The camera finishes its pan and locks.
	_set_wall(true)
	_player.state_machine.transition_to(&"Air")      # drops the last few pixels onto the floor
	while camera() and absf(camera().position.x - camera_end_x) > 0.5 and not _skip:
		await get_tree().process_frame
	_finish()


func _process(_delta: float) -> void:
	if not playing:
		return
	var down := Input.is_action_pressed(skip_action)
	if down and not _start_was_down:
		_skip = true
	_start_was_down = down


## Ends the intro (straight away if skipped): camera locked on the UFOs, wall on, Mario ready.
func _finish() -> void:
	if not playing:
		return
	playing = false
	for tw in _tweens:
		if tw.is_valid():
			tw.kill()
	_tweens.clear()
	var b := boat()
	if b:
		b.position.x = boat_dock_x
	if camera():
		camera().position.x = camera_end_x
	_set_wall(true)
	if _player.get_state_name() == &"Scripted":        # skipped: put him straight on his spot
		_player.global_position = Vector2(_land_x, _y_on_floor())
		_player.velocity = Vector2.ZERO
		_player.state_machine.transition_to(&"Ground")
	finished.emit()


func _jump_step(k: float) -> void:
	var p := _jump_from.lerp(_jump_to, k)
	p.y -= sin(k * PI) * jump_height
	_player.global_position = p


func _stand_on_boat() -> void:
	var b := boat()
	if b and _player:
		var feet := b.deck_position()
		_player.global_position = feet - Vector2(0, _feet_offset())


func _y_on_floor() -> float:
	return floor_y - _feet_offset()


func _feet_offset() -> float:
	return _player.get_feet_y() - _player.global_position.y


func _anim(action: String) -> void:
	var spr := _player.animated_sprite_2d as PlayerAnimatedSprite
	if spr:
		spr.update_prefix(_player.player_mode)
		spr.flip_h = false
		spr.speed_scale = 1.0
		spr.play_action(action)


func _set_wall(on: bool) -> void:
	var w := wall()
	if w:
		w.set_deferred("disabled", not on)


func _tween() -> Tween:
	var t := create_tween()
	_tweens.append(t)
	return t


func _wait(time: float) -> void:
	var left := time
	while left > 0.0 and not _skip:
		await get_tree().process_frame
		left -= get_process_delta_time()


func _sound(stream: AudioStream) -> void:
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
