extends Area2D

class_name SamCannon
## The SAM cannon in the load room: get in it to delete a save file.
##   Walk into it         Mario climbs in. "DELETE SAVE DATA?" pops up above it.
##   Left / Right         aim at a UFO
##   Jump                 fire: the missile blows that UFO up, the file is deleted, and a new
##                        (empty) UFO flies down from above
##   Action (run/cancel)  Mario jumps back out
##
## ART: add a Sprite2D child "Base" (the stand) and a Sprite2D child "Barrel" (rotates to aim,
## pointing RIGHT in the picture) - the placeholder drawing switches off for each one you add.
## Missile Texture / Explosion Frames replace the drawn missile and explosion, and
## Crosshair Texture replaces the drawn aiming circle.

@export var label_text: String = "ERASE"                ## written on the gun
@export var prompt_text: String = "DELETE\nSAVE DATA?"   ## pops up above while Mario is in it
@export var prompt_offset: Vector2 = Vector2(-12, -50)
@export var barrel_pivot: Vector2 = Vector2(0, -18)
@export var barrel_length: float = 14.0
@export var missile_speed: float = 160.0
@export var missile_texture: Texture2D
@export var explosion_frames: SpriteFrames               ## needs an animation called "default"
## YOUR ART for the aiming crosshair (drawn centred on the UFO). Empty = the drawn circle.
@export var crosshair_texture: Texture2D
@export var crosshair_blink: bool = true                 ## flash on and off while aiming
@export var crosshair_color: Color = Color(1, 1, 1)      ## colour of the drawn circle
@export var exit_jump: Vector2 = Vector2(-60, -200)      ## how Mario jumps back out
@export var exit_offset: Vector2 = Vector2(-30, -18)    ## where he pops out (left of the gun, so he lands clear)
@export_group("Sounds")
@export var enter_sound: AudioStream
@export var aim_sound: AudioStream
@export var fire_sound: AudioStream
@export var explode_sound: AudioStream
@export var no_data_sound: AudioStream

var player: PlayerUpdated
var occupied: bool = false
var firing: bool = false
var target_index: int = 0
var _cooldown: bool = false        # stops Mario getting straight back in after jumping out
var _aim_angle: float = -PI / 2.0
var _message: String = ""
var _message_time: float = 0.0
var _t: float = 0.0
var _held: Dictionary = {}
var _gun_label: Label
var _prompt: Label          # buttons held last frame (so a press is only seen once)


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.bit(Layers.PLAYER)
	body_entered.connect(_on_body_entered)
	_gun_label = SaveUfo.make_label(Color(1, 0.85, 0.2))
	_gun_label.name = "GunLabel"
	_gun_label.text = label_text
	_gun_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_gun_label.position = Vector2(-20, -16)
	_gun_label.size = Vector2(40, 10)
	add_child(_gun_label)
	_prompt = SaveUfo.make_label()
	_prompt.name = "PromptLabel"
	_prompt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0, 0, 0, 0.75)
	bg.content_margin_left = 2; bg.content_margin_right = 2
	bg.content_margin_top = 1; bg.content_margin_bottom = 1
	_prompt.add_theme_stylebox_override("normal", bg)
	_prompt.visible = false
	add_child(_prompt)
	body_exited.connect(_on_body_exited)
	enter_sound = _default(enter_sound, "res://Assets/SFX/doorway.wav")
	aim_sound = _default(aim_sound, "res://Assets/SFX/coin.wav")
	fire_sound = _default(fire_sound, "res://Assets/SFX/bulletbill.wav")
	explode_sound = _default(explode_sound, "res://Assets/SFX/nokobomb.wav")
	no_data_sound = _default(no_data_sound, "res://Assets/SFX/bonusgamebad.wav")


func _default(s: AudioStream, path: String) -> AudioStream:
	if s == null and ResourceLoader.exists(path):
		return load(path)
	return s


func ufos() -> Array:
	var list := get_tree().get_nodes_in_group("save_ufos")
	list.sort_custom(func(a, b): return a.slot < b.slot)
	return list


func target() -> SaveUfo:
	var list := ufos()
	return list[target_index] if target_index < list.size() else null


func _on_body_entered(body: Node2D) -> void:
	if body is PlayerUpdated and not occupied and not _cooldown and not body.is_dead:
		get_in(body)


func _on_body_exited(body: Node2D) -> void:
	if body is PlayerUpdated:
		_cooldown = false


func get_in(p: PlayerUpdated) -> void:
	player = p
	occupied = true
	player.state_machine.transition_to(&"Hidden")
	player.global_position = global_position + Vector2(0, -8)
	target_index = clampi(target_index, 0, maxi(ufos().size() - 1, 0))
	_play(enter_sound)


func get_out() -> void:
	occupied = false
	_cooldown = true
	player.global_position = global_position + exit_offset
	player.state_machine.transition_to(&"Air")
	player.velocity = exit_jump
	player.facing_dir = -1
	player = null


func _process(delta: float) -> void:
	_t += delta
	_message_time = maxf(_message_time - delta, 0.0)
	var aim := -PI / 2.0
	var t := target()
	if occupied and t:
		aim = (t.target_position() - (global_position + barrel_pivot)).angle()
	_aim_angle = lerp_angle(_aim_angle, aim, minf(delta * 10.0, 1.0))
	var barrel := get_node_or_null("Barrel") as Node2D
	if barrel:
		barrel.position = barrel_pivot
		barrel.rotation = _aim_angle
	queue_redraw()
	_prompt.visible = occupied
	if occupied:
		_prompt.text = _message if _message_time > 0.0 else prompt_text
		_prompt.reset_size()
		_prompt.position = prompt_offset - Vector2(_prompt.size.x * 0.5, 8)

	var pressed := {}
	for a in ["left", "right", "jump", "action"]:
		var down := Input.is_action_pressed(a)
		pressed[a] = down and not _held.get(a, true)    # true = ignore buttons held when getting in
		_held[a] = down
	if not occupied or firing:
		return
	if pressed.left:
		_aim(-1)
	elif pressed.right:
		_aim(1)
	elif pressed.jump:
		fire()
	elif pressed.action:
		get_out()


func _aim(step: int) -> void:
	var n := ufos().size()
	if n == 0:
		return
	target_index = wrapi(target_index + step, 0, n)
	_play(aim_sound)


## Fires at the UFO being aimed at. Empty files can't be deleted ("NO DATA").
func fire() -> void:
	var t := target()
	if t == null or t.busy:
		return
	if not OverworldMan.slot_exists(t.slot):
		_message = "NO DATA"
		_message_time = 1.2
		_play(no_data_sound)
		return
	firing = true
	_play(fire_sound)

	var missile := SamMissile.new()
	missile.texture = missile_texture
	get_parent().add_child(missile)
	var start := global_position + barrel_pivot + Vector2.RIGHT.rotated(_aim_angle) * barrel_length
	missile.global_position = start
	await missile.fly_to(t.target_position(), missile_speed)

	_play(explode_sound)
	_spawn_explosion(t.target_position())
	t.blow_up()
	OverworldMan.delete_slot(t.slot)
	await get_tree().create_timer(0.8).timeout
	await t.arrive_new()
	firing = false


func _spawn_explosion(at: Vector2) -> void:
	if explosion_frames and explosion_frames.has_animation("default"):
		var a := AnimatedSprite2D.new()
		a.sprite_frames = explosion_frames
		get_parent().add_child(a)
		a.global_position = at
		a.play("default")
		a.animation_finished.connect(a.queue_free)
	else:
		var e := SamExplosion.new()
		get_parent().add_child(e)
		e.global_position = at


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


func _draw() -> void:
	# Placeholder stand + barrel (only if you haven't added "Base" / "Barrel" sprites)
	if get_node_or_null("Base") == null:
		draw_rect(Rect2(-22, -6, 44, 6), Color(0.3, 0.34, 0.26))          # tracks
		for i in 5:
			draw_circle(Vector2(-16 + i * 8, -3), 2.0, Color(0.15, 0.17, 0.13))
		draw_rect(Rect2(-20, -16, 40, 10), Color(0.45, 0.52, 0.38))       # body
		draw_circle(barrel_pivot, 5.0, Color(0.4, 0.46, 0.34))            # turret
	if get_node_or_null("Barrel") == null:
		var tip := barrel_pivot + Vector2.RIGHT.rotated(_aim_angle) * barrel_length
		draw_line(barrel_pivot, tip, Color(0.55, 0.62, 0.48), 4.0)
		draw_line(barrel_pivot, tip, Color(0.3, 0.34, 0.26), 1.0)
	# (the words on the gun and the question are Label children: GunLabel, PromptLabel)

	if occupied:
		# Mario's head poking out of the hatch (placeholder - only with the drawn cannon)
		if get_node_or_null("Base") == null:
			draw_rect(Rect2(-8, -21, 5, 4), Color(0.9, 0.2, 0.15))
		# Crosshair on the UFO being aimed at
		var t := target()
		if t and not firing and (not crosshair_blink or int(_t * 4.0) % 2 == 0):
			var c := to_local(t.target_position())
			if crosshair_texture:
				draw_texture(crosshair_texture, (c - crosshair_texture.get_size() * 0.5).round())
				return
			var col := crosshair_color
			draw_arc(c, 9.0, 0, TAU, 16, col, 1.0)
			draw_line(c + Vector2(-12, 0), c + Vector2(-6, 0), col, 1.0)
			draw_line(c + Vector2(6, 0), c + Vector2(12, 0), col, 1.0)
			draw_line(c + Vector2(0, -12), c + Vector2(0, -6), col, 1.0)
			draw_line(c + Vector2(0, 6), c + Vector2(0, 12), col, 1.0)
