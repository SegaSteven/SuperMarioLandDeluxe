@tool
extends Node2D

class_name FakeDaisy
## The fake Princess Daisy at the end of a castle level (1-3, 2-3, 3-3 in Super Mario Land).
##
## What happens:
##   1. Mario touches the boss switch (drag it into Boss Switch): everything freezes for the
##      switch's Freeze Time, then every enemy on screen blows up. Start Delay after that the
##      Door opens (its "opening" animation + Door Sound) while Mario is still frozen. He stays
##      frozen through the pan too, then unfreezes (drops off the button) and walks in.
##   2. The camera pans over to the fake Daisy room (the pink DaisyCamArea) - Pan Delay / Pan Time.
##   3. The level music stops, the Princess Daisy (credits) music starts and Mario walks in by
##      himself from wherever he is (left or right of her), stopping Stop Distance from Daisy.
##   4. The message types out letter by letter ("OH! DAISY").
##   5. Daisy holds out her arms; the music stops as she flashes into the monster and the
##      faker music (Change Music, Oh! Daisy.wav) plays.
##   6. The monster hops away off the screen, one hop every Hop Every seconds.
##   7. After Finish Delay the level counts as beaten and the wipe takes Mario to the map.
##
## SETUP: drag res://Scenes/Cutscene/fake_daisy.tscn into the level. Move the Door and Daisy
## with Door Position / Daisy Position (or right-click the node > Editable Children and drag
## them). Drag the BossSwitch into Boss Switch and a DaisyCamArea (pink box around the room,
## res://Scenes/Camera/daisy_cam_area.tscn) into Daisy Cam Area.
## In the editor a dashed line shows where Mario stops. start() runs it from code too.
## Every time below is in seconds.

enum MusicStart { DOOR_OPENS, PAN_STARTS, MARIO_WALKS, MARIO_STOPS, MESSAGE }
enum LetterAlign { LEFT, CENTRE, RIGHT }
enum PanTo { BETWEEN_MARIO_AND_DAISY, DAISY, MIDDLE_OF_BOX }

@export_group("Setup")
@export var boss_switch: NodePath
## The pink box around the fake Daisy room. Empty = the camera doesn't pan, it just follows Mario.
@export var daisy_cam_area: NodePath
## Where the Door is (from this node).
@export var door_position: Vector2 = Vector2.ZERO:
	set(v):
		door_position = v
		_place()
## Where Daisy stands (from this node).
@export var daisy_position: Vector2 = Vector2(72, -8):
	set(v):
		daisy_position = v
		_place()
## Draw the "Mario stops here" line in the editor.
@export var show_guides: bool = true:
	set(v):
		show_guides = v
		queue_redraw()

@export_group("Timing")
## After the switch's freeze, blasts and time bonus count, before the door opens (Mario stays
## frozen until the door is all the way up).
@export var start_delay: float = 0.5
## How fast the door's opening animation plays (1 = as set in its SpriteFrames, 2 = twice as fast).
@export var door_open_speed: float = 1.0
## Pause after the door is open.
@export var after_door_pause: float = 0.3
## Pause after Mario stops, before the message.
@export var before_message_pause: float = 0.3
## Pause after the message has typed out.
@export var after_message_pause: float = 0.6
## How long Daisy holds her arms out before changing.
@export var arms_out_time: float = 0.6
## Pause after she's changed, before the first hop.
@export var after_transform_pause: float = 0.4
## After the monster has gone, before leaving the level.
@export var finish_delay: float = 1.5

@export_group("Camera pan")
## Pan over to the Daisy Cam Area (needs one set above).
@export var pan_camera: bool = true
## After the door is open, before the camera starts moving.
@export var pan_delay: float = 0.3
## How long the pan takes.
@export var pan_time: float = 0.75
## Ease in and out (off = steady speed).
@export var pan_smooth: bool = true
## Mario waits for the pan to finish before walking (off = he walks while it pans).
@export var walk_after_pan: bool = true
## What the camera centres on: the gap between Mario (where he stops) and Daisy, so Daisy is
## just off centre; Daisy herself; or the middle of the pink box.
@export var pan_to: PanTo = PanTo.BETWEEN_MARIO_AND_DAISY
## Nudge where the camera ends up (pixels).
@export var pan_offset: Vector2 = Vector2.ZERO

@export_group("Mario")
@export var walk_speed: float = 40.0
## Mario stops this many pixels before Daisy (on whichever side he comes from).
@export var stop_distance: float = 28.0:
	set(v):
		stop_distance = v
		queue_redraw()
## Keep his feet on the floor if it goes up or down while he walks.
@export var follow_floor: bool = true
## Turn to face Daisy when he stops.
@export var face_daisy: bool = true

@export_group("Message")
@export var message: String = "OH! DAISY"
@export var seconds_per_letter: float = 0.12
## A sound for each letter (optional).
@export var letter_sound: AudioStream
@export var message_color: Color = Color(1, 1, 1)
@export var font_size: int = 7
@export var shadow: bool = true
@export var shadow_color: Color = Color(0, 0, 0)
@export var shadow_offset: Vector2 = Vector2(1, 1)
## Where the text goes on the screen (screen pixels; with Centre it's centred across the screen
## and only the Y matters, plus X as a nudge).
@export var message_position: Vector2 = Vector2(0, 28)
@export var message_align: LetterAlign = LetterAlign.CENTRE
## Keep the message on screen until the end (off = it goes when Daisy changes).
@export var message_stays: bool = true

@export_group("Daisy")
@export var daisy_idle_animation: StringName = &"idle"
@export var daisy_arms_animation: StringName = &"arms_out"
## Daisy faces left (towards Mario coming from the left).
@export var daisy_faces_left: bool = true

@export_group("Monster")
## The enemy Daisy turns into. Only its look (AnimatedSprite2D frames) is used - it always hops
## away the same way. Leave empty to use Monster Frames.
@export var monster_scene: PackedScene = preload("res://Scenes/Enemies/fly.tscn")
@export var monster_frames: SpriteFrames
@export var monster_animation: StringName = &"default"
## Flip the monster's sprite.
@export var monster_flip: bool = false
## How many times it flickers between Daisy and the monster.
@export var flashes: int = 6
@export var flash_time: float = 0.12
## How high each hop goes (pixels).
@export var hop_height: float = 36.0
## How far each hop goes (pixels).
@export var hop_distance: float = 24.0
## 1 = hops away to the right, -1 = to the left.
@export_range(-1, 1, 2) var hop_direction: int = 1
## One hop every this many seconds.
@export var hop_every: float = 1.0
## How long it's in the air for each hop (the rest of Hop Every it waits on the ground).
@export var hop_air_time: float = 0.6
## 0 = keep hopping until it's off the screen; otherwise this many hops, then it vanishes.
@export var hop_count: int = 0

@export_group("Sounds")
@export var door_sound: AudioStream = preload("res://Assets/SFX/doorway.wav")
## The Princess Daisy (credits) music.
@export var music: AudioStream = preload("res://Assets/Audio/16 Princess Daisy.mp3")
@export var music_volume_db: float = 0.0
## When the music starts.
@export var music_starts: MusicStart = MusicStart.MARIO_WALKS
## Time Daisy's change to the music: she changes exactly when the music reaches Change At
## (the credits song switches at 8 s), and Mario walks faster if he needs to so the message
## and her arms-out pose fit in before then.
@export var sync_to_music: bool = true
## Seconds into the music when Daisy changes.
@export var change_at_music_time: float = 8.0
## The fastest Mario will walk to make it in time (90 = his running speed).
@export var max_walk_speed: float = 90.0
## Stop the music the moment Daisy's sprite changes (off = it keeps playing to the end).
@export var music_stops_on_change: bool = true
## The "faker" music that plays the moment Daisy changes into the monster.
@export var change_music: AudioStream = preload("res://Assets/Audio/Original/Oh! Daisy.wav")
@export var change_music_volume_db: float = 0.0
## Don't leave the level until the faker music has finished.
@export var wait_for_change_music: bool = true
## Optional extra sound when the message starts typing (e.g. Assets/Audio/Original/Oh! Daisy.wav).
@export var jingle: AudioStream
@export var transform_sound: AudioStream = preload("res://Assets/SFX/daisytransform.wav")
## A sound for each hop (optional).
@export var hop_sound: AudioStream
@export var sfx_volume_db: float = 0.0

@export_group("Finishing")
## Count the level as beaten (off = just leave).
@export var counts_as_win: bool = true
## Where to go afterwards (empty = back to the map Mario came from).
@export_file("*.tscn") var go_to: String = ""
## Where Mario appears there (like Door Normal's Spawn Point; zero = the scene's own start).
@export var spawn_point: Vector2 = Vector2.ZERO
## Unlock name(s) beating the level gives, comma separated (same as Door Normal).
@export var unlocks: String = ""
@export var transition_pattern: String = "squares"
@export var transition_speed: float = 4.0
@export_group("")

signal door_opened
signal mario_arrived
signal transformed
signal finished

var door: Node2D
var door_sprite: AnimatedSprite2D
var door_shape: CollisionShape2D
var daisy: AnimatedSprite2D

var _running: bool = false
var _music: AudioStreamPlayer
var _change_player: AudioStreamPlayer
var _label: Label
var _pan_done: bool = true


func _ready() -> void:
	door = get_node_or_null("Door")
	door_sprite = get_node_or_null("Door/AnimatedSprite2D")
	door_shape = get_node_or_null("Door/CollisionShape2D")
	daisy = get_node_or_null("Daisy")
	_place()
	if Engine.is_editor_hint():
		return
	_show(door_sprite, &"closed")
	if daisy:
		daisy.flip_h = daisy_faces_left
		_show(daisy, daisy_idle_animation)
	var sw := get_node_or_null(boss_switch)
	var sig := &"done" if sw and sw.has_signal("done") else &"pressed"
	if sw and sw.has_signal(sig):
		sw.connect(sig, func():
			await _wait(start_delay)
			start())


## Puts the Door and Daisy where Door Position / Daisy Position say.
func _place() -> void:
	if not is_inside_tree():
		return
	var d := get_node_or_null("Door") as Node2D
	if d:
		d.position = door_position
	var dz := get_node_or_null("Daisy") as Node2D
	if dz:
		dz.position = daisy_position
	queue_redraw()


func start() -> void:
	if _running:
		return
	_running = true
	_stop_level_music()
	if music_starts == MusicStart.DOOR_OPENS:
		_start_music()
	await _open_door()
	door_opened.emit()
	var m := GameManager.player as PlayerUpdated
	await _wait(after_door_pause)
	_start_pan()
	if walk_after_pan:
		while not _pan_done:
			await get_tree().process_frame
	# The pan is done: Mario unfreezes - drops off the button and stands normally
	if m and is_instance_valid(m) and not m.is_dead:
		if m.get_state_name() != &"Scripted":
			m.state_machine.transition_to(&"Scripted")
		var spr: AnimatedSprite2D = m.animated_sprite_2d
		if spr:
			spr.play()
		await _drop_to_floor(m)
		if spr:
			spr.trigger_animation(Vector2.ZERO, 0.0, m.player_mode)
	if music_starts == MusicStart.MARIO_WALKS:
		_start_music()
	if m and is_instance_valid(m) and not m.is_dead:
		await _drop_to_floor(m)
		await _walk_in(m)
	mario_arrived.emit()
	if music_starts == MusicStart.MARIO_STOPS:
		_start_music()
	await _wait(before_message_pause)
	if music_starts == MusicStart.MESSAGE:
		_start_music()
	_play(jingle)
	await _type_message()
	await _wait(after_message_pause)
	await _transform()
	transformed.emit()
	await _wait(after_transform_pause)
	await _hop_away()
	if wait_for_change_music:
		while is_instance_valid(_change_player) and _change_player.playing:
			await get_tree().process_frame
	await _wait(finish_delay)
	finished.emit()
	_finish_level()


func _wait(t: float) -> void:
	if t > 0.0:
		await get_tree().create_timer(t).timeout


func _show(spr: AnimatedSprite2D, anim: StringName) -> bool:
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation(anim):
		spr.play(anim)
		return true
	return false


# --- door -------------------------------------------------------------------------------

func _open_door() -> void:
	_play(door_sound)
	if door_sprite and _show(door_sprite, &"opening"):
		door_sprite.speed_scale = maxf(door_open_speed, 0.01)
		await door_sprite.animation_finished
		door_sprite.speed_scale = 1.0
	_show(door_sprite, &"open")
	if door_shape:
		door_shape.set_deferred("disabled", true)


# --- camera -----------------------------------------------------------------------------

func _start_pan() -> void:
	var area := get_node_or_null(daisy_cam_area) as CamArea
	var cam := get_viewport().get_camera_2d()
	if not pan_camera or area == null or cam == null:
		return
	_pan_done = false
	_pan(cam, area.area_rect())


func _pan(cam: Camera2D, r: Rect2) -> void:
	await _wait(pan_delay)
	if music_starts == MusicStart.PAN_STARTS:
		_start_music()
	var half := cam.get_viewport_rect().size * 0.5 / cam.zoom
	var to := r.get_center()
	if daisy and pan_to != PanTo.MIDDLE_OF_BOX:
		to.x = daisy.global_position.x
		if pan_to == PanTo.BETWEEN_MARIO_AND_DAISY:
			to.x = (daisy.global_position.x + mario_stop_x()) * 0.5
	# Up / down it stays inside the pink box (its middle if the box is one screen tall)
	to.y = clampf(to.y, r.position.y + half.y, maxf(r.end.y - half.y, r.position.y + half.y))
	to += pan_offset
	var from := cam.get_screen_center_position()
	# Take the camera over: MainCamArea stands down, Mario may go off screen, no edges while moving
	if cam.has_meta("cam_area_glide"):
		var old: Tween = cam.get_meta("cam_area_glide")
		if old and old.is_valid():
			old.kill()
	cam.set_meta("cam_locked", true)
	cam.set_meta("no_death_line", true)
	cam.set_meta("cam_free", true)
	cam.position_smoothing_enabled = false
	cam.drag_horizontal_enabled = false
	cam.drag_vertical_enabled = false
	cam.limit_left = -10000000
	cam.limit_top = -10000000
	cam.limit_right = 10000000
	cam.limit_bottom = 10000000
	cam.set_meta("cam_area_x", from.x)
	cam.set_meta("cam_area_y", from.y)
	if pan_time > 0.0:
		var tw := create_tween()
		if pan_smooth:
			tw.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
		tw.tween_method(func(p: float):
			cam.set_meta("cam_area_x", lerpf(from.x, to.x, p))
			cam.set_meta("cam_area_y", lerpf(from.y, to.y, p)), 0.0, 1.0, pan_time)
		await tw.finished
	cam.set_meta("cam_area_x", to.x)
	cam.set_meta("cam_area_y", to.y)
	# Stay put there (the pink box, stretched if the centring needs a bit more room)
	var view := Rect2(to - half, half * 2.0).merge(r)
	cam.limit_left = int(floor(view.position.x))
	cam.limit_top = int(floor(view.position.y))
	cam.limit_right = int(ceil(view.end.x))
	cam.limit_bottom = int(ceil(view.end.y))
	_pan_done = true


## Where Mario will stop: Stop Distance before Daisy, on the side he's coming from.
func mario_stop_x() -> float:
	var m := GameManager.player as Node2D
	var from_left := m == null or not is_instance_valid(m) or m.global_position.x <= daisy.global_position.x
	return daisy.global_position.x + (-stop_distance if from_left else stop_distance)


# --- Mario ------------------------------------------------------------------------------

## Walks Mario to Daisy from wherever he is - left or right of her, however far.
func _walk_in(m: PlayerUpdated) -> void:
	var target_x := mario_stop_x()
	var dir := signf(target_x - m.global_position.x)
	var spr: AnimatedSprite2D = m.animated_sprite_2d
	var speed := _walk_speed_for(absf(target_x - m.global_position.x))
	while dir != 0.0 and absf(target_x - m.global_position.x) > 0.01:
		var step := speed * get_physics_process_delta_time()
		var nx := m.global_position.x + dir * step
		m.global_position.x = minf(nx, target_x) if dir > 0.0 else maxf(nx, target_x)
		if follow_floor:
			_stick_to_floor(m)
		spr.trigger_animation(Vector2(speed * dir, 0), dir, m.player_mode)
		await get_tree().physics_frame
	spr.trigger_animation(Vector2.ZERO, 0.0, m.player_mode)
	if face_daisy:
		spr.flip_h = daisy.global_position.x < m.global_position.x


## Walk Speed, or faster (up to Max Walk Speed) so that after he stops, the message, the pauses
## and Daisy's arms-out pose all fit in before the music reaches Change At.
func _walk_speed_for(distance: float) -> float:
	if not sync_to_music or not _music_playing() or distance <= 0.0:
		return walk_speed
	var after := before_message_pause + seconds_per_letter * message.length() + after_message_pause + arms_out_time
	var left := change_at_music_time - _music_time() - after
	if left <= 0.0:
		return maxf(max_walk_speed, walk_speed)
	return clampf(distance / left, walk_speed, maxf(max_walk_speed, walk_speed))


func _music_playing() -> bool:
	return _music != null and is_instance_valid(_music) and _music.playing


## How far into the music it is (seconds).
func _music_time() -> float:
	if not _music_playing():
		return 0.0
	return _music.get_playback_position() + AudioServer.get_time_since_last_mix()


## If Mario is in the air (no gravity in the cutscene), drops him onto the floor below.
func _drop_to_floor(m: PlayerUpdated) -> void:
	var speed := 0.0
	for i in 600:
		var feet := m.get_feet_y()
		var q := PhysicsRayQueryParameters2D.create(Vector2(m.global_position.x, feet - 2.0),
			Vector2(m.global_position.x, feet + 400.0), Layers.WORLD_MASK, [m.get_rid()])
		var hit := m.get_world_2d().direct_space_state.intersect_ray(q)
		if hit.is_empty() or hit.position.y - feet <= 0.5:
			if hit:
				m.global_position.y += hit.position.y - feet
			# Let Godot see he's on the ground again (so he stands / walks, not the jump pose)
			m.velocity = Vector2(0, 20)
			m.move_and_slide()
			m.velocity = Vector2.ZERO
			return
		speed = minf(speed + 400.0 * get_physics_process_delta_time(), 250.0)
		m.global_position.y += minf(speed * get_physics_process_delta_time(), hit.position.y - feet)
		await get_tree().physics_frame


## Keeps Mario's feet on the ground under him (he has no gravity during the cutscene).
func _stick_to_floor(m: PlayerUpdated) -> void:
	var feet := m.get_feet_y()
	var q := PhysicsRayQueryParameters2D.create(Vector2(m.global_position.x, feet - 12.0),
		Vector2(m.global_position.x, feet + 24.0), Layers.WORLD_MASK, [m.get_rid()])
	var hit := m.get_world_2d().direct_space_state.intersect_ray(q)
	if hit:
		m.global_position.y += hit.position.y - feet


# --- message ----------------------------------------------------------------------------

func _type_message() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 20
	add_child(layer)
	_label = SaveUfo.make_label(message_color, font_size)
	if shadow:
		_label.label_settings.shadow_color = shadow_color
		_label.label_settings.shadow_size = 0
		_label.label_settings.shadow_offset = shadow_offset
	else:
		_label.label_settings.shadow_color = Color(0, 0, 0, 0)
	_label.horizontal_alignment = [HORIZONTAL_ALIGNMENT_LEFT, HORIZONTAL_ALIGNMENT_CENTER, HORIZONTAL_ALIGNMENT_RIGHT][message_align]
	_label.position = message_position
	_label.size = Vector2(get_viewport_rect().size.x, font_size + 3)
	layer.add_child(_label)
	_label.text = ""
	for i in message.length():
		_label.text = message.substr(0, i + 1)
		if letter_sound and message[i] != " ":
			_play(letter_sound)
		await _wait(seconds_per_letter)


# --- transform and hops -----------------------------------------------------------------

func _monster_frames() -> SpriteFrames:
	if monster_scene:
		var inst := monster_scene.instantiate()
		var frames: SpriteFrames = null
		for c in inst.find_children("*", "AnimatedSprite2D", true, false):
			frames = (c as AnimatedSprite2D).sprite_frames
			break
		inst.free()
		if frames:
			return frames
	return monster_frames


func _show_monster(frames: SpriteFrames) -> void:
	daisy.sprite_frames = frames
	daisy.play(monster_animation if frames.has_animation(monster_animation) else frames.get_animation_names()[0])
	daisy.flip_h = monster_flip


func _transform() -> void:
	if _show(daisy, daisy_arms_animation):
		await _wait(arms_out_time)
	if sync_to_music:
		while _music_playing() and _music_time() < change_at_music_time:
			await get_tree().process_frame
	var daisy_frames := daisy.sprite_frames
	var daisy_anim := daisy.animation
	var frames := _monster_frames()
	if music_stops_on_change:
		_stop_music()
	if not message_stays and _label:
		_label.visible = false
	_play(transform_sound)
	_start_change_music()
	for i in flashes:
		if i % 2 == 0 and frames:
			_show_monster(frames)
		else:
			daisy.sprite_frames = daisy_frames
			daisy.play(daisy_anim)
			daisy.flip_h = daisy_faces_left
		await _wait(flash_time)
	if frames:
		_show_monster(frames)


## One hop every Hop Every seconds until it's off the screen (or Hop Count hops).
func _hop_away() -> void:
	var cam := get_viewport().get_camera_2d()
	var half_w := get_viewport_rect().size.x * 0.5
	var centre_x := cam.get_screen_center_position().x if cam else daisy.global_position.x
	var air := minf(hop_air_time, hop_every) if hop_every > 0.0 else hop_air_time
	var n := 0
	while true:
		if hop_count > 0 and n >= hop_count:
			break
		if hop_count <= 0 and absf(daisy.global_position.x - centre_x) > half_w + 16.0:
			break
		var start := daisy.position
		_play(hop_sound)
		var tw := create_tween()
		tw.tween_method(func(t: float):
			daisy.position = Vector2(start.x + hop_direction * hop_distance * t, start.y - hop_height * 4.0 * t * (1.0 - t)),
			0.0, 1.0, maxf(air, 0.05))
		await tw.finished
		n += 1
		if hop_every > air:
			await _wait(hop_every - air)
	daisy.visible = false


# --- sound ------------------------------------------------------------------------------

func _start_music() -> void:
	if music == null or _music != null:
		return
	_music = AudioStreamPlayer.new()
	_music.stream = music
	_music.volume_db = music_volume_db
	_music.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_music)
	_music.play()


func _start_change_music() -> void:
	if change_music == null:
		return
	_change_player = AudioStreamPlayer.new()
	_change_player.stream = change_music
	_change_player.volume_db = change_music_volume_db
	_change_player.process_mode = Node.PROCESS_MODE_ALWAYS
	add_child(_change_player)
	_change_player.play()
	# Play it ONCE, even if the file has loop points in it
	var p := _change_player
	var length := change_music.get_length()
	p.finished.connect(p.queue_free)
	if length > 0.0:
		await get_tree().create_timer(length).timeout
		if is_instance_valid(p):
			p.stop()
			p.queue_free()


func _stop_music() -> void:
	if _music and is_instance_valid(_music):
		_music.stop()
		_music.queue_free()
	_music = null


func _stop_level_music() -> void:
	var lvl := get_tree().current_scene
	var lm := lvl.get_node_or_null("LevelMusic") as AudioStreamPlayer if lvl else null
	if lm:
		lm.stop()


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	p.volume_db = sfx_volume_db
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


# --- finishing --------------------------------------------------------------------------

func _finish_level() -> void:
	if counts_as_win:
		GameManager.win()
		for key in unlocks.split(",", false):
			OverworldMan.unlock(key.strip_edges())
	var dest := go_to
	if dest == "":
		dest = OverworldMan.last_map_scene if OverworldMan.last_map_scene != "" else "res://Scenes/WorldScenes/world_map.tscn"
	GameManager.travel_to(dest, spawn_point, {"pattern": transition_pattern, "speed": transition_speed})


# --- editor guide -----------------------------------------------------------------------

func _draw() -> void:
	if not Engine.is_editor_hint() or not show_guides:
		return
	var col := Color(1.0, 0.4, 0.8)
	var x := daisy_position.x - stop_distance
	var floor_y := door_position.y
	var y := floor_y
	while y > floor_y - 32.0:
		draw_line(Vector2(x, y), Vector2(x, maxf(y - 3.0, floor_y - 32.0)), col, 1.0)
		y -= 6.0
	draw_string(ThemeDB.fallback_font, Vector2(x - 20, floor_y - 35), "MARIO STOPS", HORIZONTAL_ALIGNMENT_LEFT, -1, 6, col)
