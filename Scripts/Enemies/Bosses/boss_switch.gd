extends Area2D

class_name BossSwitch
## The switch behind the boss (Super Mario Land worlds 1-3, 2-3, 3-3).
## When Mario touches it: the boss is beaten (falls off-screen), the music stops, and anything
## in "Reveal Nodes" appears - put your exit DoorNormal there so the level can be finished.
##
## Setup:
##   1. Instance res://Scenes/Enemies/Bosses/boss_switch.tscn behind the boss.
##   2. Bosses: drag the boss node in (leave empty = every Boss in the level).
##   3. Reveal Nodes: drag the exit door in. It stays hidden and switched off until pressed.
## Pressing it also freezes the clock and counts the time left into the score (Time Bonus).
##
## BLOW UP: pressing it blows up every enemy on the screen - bosses too, and their shots
## (fireballs, bubbles, spears, boulders...). Each one turns into a Blast (Scenes/Effects/
## blast.tscn - change its frames) and gives its points; shots worth nothing give Shot Points.
## Bosses off the screen are still beaten (they fall, like before).
## ORDER: Mario touches it -> everything freezes while Freeze Sound (12 Level End.mp3, the stage complete music)
## plays -> once it's finished it all blows up ("blasted") -> the time bonus is counted into
## the score -> "done": the FakeDaisy door goes up (Mario still frozen until it's fully open),
## then the pan, then he walks in.
## THE SPRITE: AnimatedSprite2D "default" (up) and "pressed" - placeholders in
## Assets/Sprites/BossSwitch/, 8 x 8 like a block.

signal pressed
## After the freeze, once everything has blown up.
signal blasted
## After the blasts AND the time bonus count - the FakeDaisy cutscene starts from this.
signal done

@export var bosses: Array[NodePath] = []
@export var reveal_nodes: Array[NodePath] = []
@export var stop_music: bool = true
@export var press_points: int = 0             ## extra points for pressing it
## Stop the clock and count the time left into the score, like reaching the exit door.
@export var time_bonus: bool = true
## Seconds after the blasts before the count starts. The clock is frozen straight away.
@export var time_bonus_delay: float = 0.5

## Only pressed when Mario lands on top of it (jumping onto it), not walking into its side.
@export var press_from_above_only: bool = true

@export_group("Freeze")
## Everything (Mario, enemies, shots) stands frozen, like the game is paused, for as long as
## the Freeze Sound (the stage complete sound) plays, then it all blows up. Freeze Time is only
## used if there's no Freeze Sound (or to make the freeze longer than it). 0 = just the sound.
@export var freeze_time: float = 0.0
## Plays as everything freezes. The freeze lasts exactly as long as this sound.
@export var freeze_sound: AudioStream = preload("res://Assets/Audio/12 Level End.mp3")
## Mario stays frozen after that too, until a cutscene (FakeDaisy) moves him. If nothing is
## connected to "blasted" he gets his controls back straight after the blasts.
@export var hold_mario: bool = true

@export_group("Blow up")
## Blow up every enemy (and enemy shot) on the screen when it's pressed.
@export var blow_up_on_screen: bool = true
@export var blast_scene: PackedScene = preload("res://Scenes/Effects/blast.tscn")
## Points for a shot (fireball, bubble...) or anything else normally worth 0.
@export var shot_points: int = 100
## Seconds between each blast (0 = all at once).
@export var blast_stagger: float = 0.0
## Counts as "on the screen" this many pixels past the edges too.
@export var screen_margin: float = 8.0
@export var blast_sound: AudioStream = preload("res://Assets/SFX/nokobomb.wav")
@export_group("")

var is_pressed: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.bit(Layers.PLAYER)
	body_entered.connect(_on_body_entered)
	for path in reveal_nodes:
		var n := get_node_or_null(path)
		if n:
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
	if sprite and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")


func _on_body_entered(body: Node2D) -> void:
	if is_pressed or not body is PlayerUpdated:
		return
	if body.is_dead:
		return
	if press_from_above_only and not _landing_on(body):
		return                              # touching its side: _physics_process keeps checking
	press()


func _physics_process(_delta: float) -> void:
	if is_pressed or not press_from_above_only:
		return
	for b in get_overlapping_bodies():
		if b is PlayerUpdated and not b.is_dead and _landing_on(b):
			press()
			return


## The top of the switch.
func _top_y() -> float:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs and cs.shape:
		return cs.global_position.y - cs.shape.get_rect().size.y * 0.5
	return global_position.y - 4.0


## Mario coming down onto the top of it (not rising, feet at the top).
func _landing_on(m: PlayerUpdated) -> bool:
	return m.velocity.y >= 0.0 and m.get_feet_y() <= _top_y() + 4.0


func press() -> void:
	is_pressed = true
	if sprite and sprite.sprite_frames.has_animation("pressed"):
		sprite.play("pressed")
	# (no press sound of its own - the Freeze Sound below is the switch's sound. An optional
	# AudioStreamPlayer child called PressSound still plays if you add one.)
	var sfx := get_node_or_null("PressSound") as AudioStreamPlayer
	if sfx:
		sfx.process_mode = Node.PROCESS_MODE_ALWAYS
		sfx.play()

	if stop_music:
		var music := get_tree().current_scene.get_node_or_null("LevelMusic") as AudioStreamPlayer
		if music:
			music.stop()
	if press_points > 0:
		GameManager.on_points_scored(press_points)

	var ui: UI = UI.find(get_tree()) if time_bonus else null
	if ui:
		ui.stop_time()

	# Mario stops dead (he can't be hurt now) and stays that way until the cutscene moves him
	var mario := GameManager.player as PlayerUpdated
	if hold_mario and mario and is_instance_valid(mario) and not mario.is_dead:
		mario.state_machine.transition_to(&"Scripted")
		mario.velocity = Vector2.ZERO
		if press_from_above_only:
			mario.global_position.y += _top_y() - mario.get_feet_y()     # standing on it
		if mario.animated_sprite_2d:
			mario.animated_sprite_2d.pause()

	var targets: Array = _on_screen_enemies() if blow_up_on_screen else []
	pressed.emit()

	# Everything freezes, like the game is paused...
	var hold := freeze_time
	if freeze_sound:
		hold = maxf(hold, freeze_sound.get_length())
	if hold > 0.0:
		process_mode = Node.PROCESS_MODE_ALWAYS
		get_tree().paused = true
		if freeze_sound:
			var fs := AudioStreamPlayer.new()
			fs.stream = freeze_sound
			fs.process_mode = Node.PROCESS_MODE_ALWAYS
			add_child(fs)
			fs.play()
			get_tree().create_timer(freeze_sound.get_length(), true, false, true).timeout.connect(fs.queue_free)
		await get_tree().create_timer(hold, true, false, true).timeout
		get_tree().paused = false
		process_mode = Node.PROCESS_MODE_INHERIT

	# ...then it all blows up
	for boss in _get_bosses():
		if not boss.is_defeated and not targets.has(boss):
			boss.defeat()                   # off the screen: falls, like before
	await _blow_up(targets)

	for path in reveal_nodes:
		var n := get_node_or_null(path)
		if n:
			n.visible = true
			n.process_mode = Node.PROCESS_MODE_INHERIT

	blasted.emit()

	# The time left is counted into the score...
	if ui:
		await get_tree().create_timer(time_bonus_delay, false).timeout
		await ui.tally_time_bonus()

	# ...and once that's done the cutscene (FakeDaisy) starts
	done.emit()
	# Nothing (like a FakeDaisy) took Mario over: give him his controls back
	if hold_mario and done.get_connections().is_empty() and mario and is_instance_valid(mario) and not mario.is_dead:
		if mario.animated_sprite_2d:
			mario.animated_sprite_2d.play()
		mario.state_machine.transition_to(&"Ground")


func _get_bosses() -> Array:
	var out: Array = []
	if bosses.is_empty():
		for b in get_tree().get_nodes_in_group("boss"):
			if b is Boss:
				out.append(b)
	else:
		for path in bosses:
			var b := get_node_or_null(path)
			if b is Boss:
				out.append(b)
	return out


## Every enemy, boss and enemy shot on the screen right now.
func _on_screen_enemies() -> Array:
	var out: Array = []
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return out
	var size := cam.get_viewport_rect().size / cam.zoom
	var view := Rect2(cam.get_screen_center_position() - size * 0.5, size).grow(screen_margin)
	for e in get_tree().get_nodes_in_group("enemy"):
		if not (e is Enemy) or e.is_dead or not e.is_inside_tree() or not e.is_visible_in_tree():
			continue
		var at: Vector2 = e.sprite.global_position if e.sprite else e.global_position
		if view.has_point(at):
			out.append(e)
	return out


func _blow_up(targets: Array) -> void:
	if targets.is_empty():
		return
	if blast_sound:
		var p := AudioStreamPlayer.new()
		p.stream = blast_sound
		get_tree().current_scene.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	for e in targets:
		if not is_instance_valid(e) or e.is_dead:
			continue
		var pts: int = e.score if e.score > 0 else shot_points
		e.blow_up(pts, blast_scene)
		if blast_stagger > 0.0:
			await get_tree().create_timer(blast_stagger, false).timeout
