extends CharacterBody2D

class_name PlayerUpdated
## Mario. This script holds the shared "tools" (physics helpers, power-ups, star, hit detection,
## the signals your levels connect to). WHAT Mario does each frame is decided by his states:
## the child node "StateMachine" and its children (Ground, Air, Transform, Pipe, Dead).
## Add your own move by adding a state - see Scripts/Player/PlayerState.gd and the guide.
##
## How enemies talk to Mario (so you can add new ones easily):
##   - Mario's Area2D "sees" every body touching him each physics frame.
##   - If the body is an Enemy, Mario decides: star -> enemy.die_from_hit(),
##     falling onto its head -> enemy.stomp(self), anything else -> enemy.touch_player(self).
##   - The Enemy decides what happens next (die, turn into a shell, hurt Mario...).

# --- Signals (names are used by your level scenes - don't rename) -------------
signal points_scored(points: int)
signal scene_under_change
signal scene_overD1_change
signal scene_overD2_change
signal super_mode_play
signal super_mode_stop

## Mario's sizes / power-ups. Add new ones at the END (saves store the number).
## The full power-up list (what each gives, unlocks, projectiles) is Scripts/Player/PowerUps.gd.
enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING,   # Superball Flower
	FIRE,       # Fire Flower
	BUNNY,      # Bunny ears (Super Mario Land 2 carrot)
}

const POINTS_LABEL_SCENE = preload("res://Scenes/points_label.tscn")
const SUPERBALL_SCENE = preload("res://Scenes/superball.tscn")

const SMALL_SHAPE = preload("res://Resources/CollisionShapes/Small_Mario_Collision_Shape_Normal.tres")
const SMALL_JUMP_SHAPE = preload("res://Resources/CollisionShapes/Small_Mario_Jump_Collision_Shape.tres")
const BIG_SHAPE = preload("res://Resources/CollisionShapes/Big_Mario_Collision_Shape_Normal.tres")

## All Mario sprites are 16x16 and centred on the node, so his feet are 8px below the origin.
const FEET_Y := 8.0

# --- Tuning (all editable in the Inspector) ------------------------------------
@export_group("Movement")
@export var max_walk_speed: float = 60.0
@export var max_run_speed: float = 90.0     ## Game Boy feel: ~1.5 px a frame (walk is 1 px a frame)
@export var walk_accel: float = 800.0
@export var stop_decel: float = 1000.0
@export var turn_decel: float = 1400.0   ## extra braking when you push the opposite way (skid)
@export var air_decel: float = 250.0
@export var block_backtracking: bool = true   ## like the Game Boy game: can't walk off the left of the screen

@export_group("Jumping")
@export var jump_velocity: float = -180.0
@export var gravity_rise: float = 350.0
@export var gravity_fall: float = 500.0
@export var max_fall_speed: float = 260.0
@export var jump_cut: float = 0.5        ## releasing jump early multiplies upward speed by this
@export var coyote_time: float = 0.08    ## can still jump this long after leaving a ledge
@export var jump_buffer: float = 0.10    ## jump pressed this early before landing still counts

@export_group("Stomping")
@export var stomp_bounce: float = -150.0
@export var stomp_bounce_held: float = -220.0   ## bounce height while holding jump
@export var stomp_tolerance: float = 7.0        ## how far below an enemy's head still counts as a stomp

@export_group("Powerups")
@export var star_duration: float = 0.0        ## 0 = lasts exactly as long as the star song
@export var star_flash_speed: float = 0.06    ## seconds per flash step
@export var star_warning_time: float = 2.0    ## flashes faster for this long before it ends
@export var iframe_duration: float = 2.0
@export var max_superballs: int = 2
@export var pipe_center_tolerance: float = 6.0
@export var speed_shoes_multiplier: float = 2.0     ## how much faster the speed shoes make Mario
@export var afterimage_interval: float = 0.05       ## speed shoes trail: seconds between ghosts

# --- State ---------------------------------------------------------------------
var player_mode: PlayerMode = PlayerMode.SMALL
var can_take_damage: bool = true
var super_star_on: bool = false
var is_dead: bool = false
var shooting: bool = false
var facing_dir: int = 1

var _buffer_left: float = 0.0
var _shoot_pose_left: float = 0.0
var _iframe_tween: Tween
var _star_tween: Tween
var _star_token: int = 0
var touching_vine: Vine = null         # set by a Vine while Mario overlaps it
var speed_multiplier: float = 1.0      # 2.0 while the speed shoes are on
var speed_shoes_on: bool = false
var _shoes_token: int = 0
var _afterimage_left: float = 0.0
var _iframe_token: int = 0

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var body_collision_shape: CollisionShape2D = $BodyCollisionShape
@onready var area_2d: Area2D = $Area2D
@onready var area_collision_shape: CollisionShape2D = $Area2D/AreaCollisionShape
@onready var shooting_point: Marker2D = $AnimatedSprite2D/ShootingPoint

var state_machine: PlayerStateMachine

const DEFAULT_STATES = {
	&"Ground": preload("res://Scripts/Player/States/ground.gd"),
	&"Air": preload("res://Scripts/Player/States/air.gd"),
	&"Transform": preload("res://Scripts/Player/States/transform.gd"),
	&"Pipe": preload("res://Scripts/Player/States/pipe.gd"),
	&"Dead": preload("res://Scripts/Player/States/dead.gd"),
	&"Vehicle": preload("res://Scripts/Player/States/vehicle.gd"),
	&"BunnyFloat": preload("res://Scripts/Player/States/bunny_float.gd"),
	&"Climb": preload("res://Scripts/Player/States/climb.gd"),
}


func _ready():
	GameManager.player = self
	add_to_group("player")
	player_mode = GameManager.player_mode

	# Mario's body only collides with the world. Enemies/items are detected by the Area2D,
	# so an enemy can never block Mario - that's what makes stomping possible.
	collision_layer = Layers.bit(Layers.PLAYER)
	collision_mask = Layers.bit(Layers.GROUND) | Layers.bit(Layers.OBSTACLE)

	area_2d.collision_layer = Layers.bit(Layers.PLAYER)
	area_2d.collision_mask = (Layers.bit(Layers.ENEMY) | Layers.bit(Layers.KOOPA_STOMP)
		| Layers.bit(Layers.BONUS) | Layers.bit(Layers.PLANT))

	update_collision_shapes(false)
	apply_power_up_tint()

	if GameManager.spawn_point != Vector2.ZERO:
		global_position = GameManager.spawn_point

	_setup_state_machine()


## Uses the StateMachine node in the scene. If it's missing (old player scene), builds the
## default states in code so Mario still works.
func _setup_state_machine() -> void:
	state_machine = get_node_or_null("StateMachine") as PlayerStateMachine
	if state_machine == null:
		state_machine = PlayerStateMachine.new()
		state_machine.name = "StateMachine"
		add_child(state_machine)
	for state_name in DEFAULT_STATES:
		if not state_machine.has_node(NodePath(String(state_name))):
			var st: PlayerState = DEFAULT_STATES[state_name].new()
			st.name = state_name
			state_machine.add_child(st)
	state_machine.setup(self)


## Which state Mario is in right now, e.g. &"Ground".
func get_state_name() -> StringName:
	return state_machine.state.name if state_machine and state_machine.state else &""


# =============================================================================
# Main loop
# =============================================================================
func _physics_process(delta: float) -> void:
	# Remember a jump press for a few frames (so pressing jump just before landing still works)
	if Input.is_action_just_pressed("jump"):
		_buffer_left = jump_buffer
	else:
		_buffer_left = maxf(_buffer_left - delta, 0.0)
	_shoot_pose_left = maxf(_shoot_pose_left - delta, 0.0)

	state_machine.physics_update(delta)


# =============================================================================
# Movement tools the states use
# =============================================================================
## The normal "Mario is in control" frame: gravity, left/right, shooting, moving,
## blocks and pipes, the camera edge, enemies/pickups, animation. Ground and Air both call it.
func run_movement(delta: float) -> void:
	var input_dir: float = Input.get_axis("left", "right")
	apply_gravity(delta)
	apply_horizontal(delta, input_dir)
	try_shoot()
	move_and_slide()
	post_move(input_dir)


## Everything after move_and_slide(): blocks and pipes, the camera edge, enemies and items,
## animation. Call it from your own states after moving Mario yourself (see bunny_float.gd).
func post_move(input_dir: float = 0.0) -> void:
	if _handle_slide_collisions(input_dir):
		return   # went into a pipe
	_keep_inside_camera()
	check_contacts()
	animate(input_dir)
	_update_afterimages(get_physics_process_delta_time())


## Throws this power-up's projectile when the action button is pressed (if it has one).
func try_shoot() -> void:
	if Input.is_action_just_pressed("action") and current_projectile() != "":
		shoot()


## The projectile scene path for Mario's current power-up ("" = can't shoot).
func current_projectile() -> String:
	return PowerUps.for_mode(player_mode).get("projectile", "")


## The state Mario enters when jump is HELD while falling (bunny ears float), or &"".
func air_hold_state() -> StringName:
	return StringName(PowerUps.for_mode(player_mode).get("air_hold_state", ""))


func animate(input_dir: float = 0.0) -> void:
	animated_sprite_2d.trigger_animation(velocity, input_dir, player_mode, _shoot_pose_left > 0.0)


func apply_gravity(delta: float) -> void:
	if is_on_floor():
		return
	var g := gravity_rise if velocity.y < 0.0 else gravity_fall
	velocity.y = minf(velocity.y + g * delta, max_fall_speed)


func apply_horizontal(delta: float, direction: float) -> void:
	var top_speed := max_run_speed if Input.is_action_pressed("action") else max_walk_speed
	top_speed *= speed_multiplier

	if direction != 0.0:
		facing_dir = 1 if direction > 0.0 else -1
		var braking: bool = is_on_floor() and signf(velocity.x) == -signf(direction) and absf(velocity.x) > 10.0
		var accel := (turn_decel if braking else walk_accel) * speed_multiplier
		velocity.x = move_toward(velocity.x, direction * top_speed, accel * delta)
	else:
		var decel := stop_decel if is_on_floor() else air_decel
		velocity.x = move_toward(velocity.x, 0.0, decel * delta)


## True when Mario is on a vine and holding Up (Ground and Air switch to Climb on this).
func wants_to_climb() -> bool:
	return touching_vine != null and is_instance_valid(touching_vine) and Input.is_action_pressed("Up") \
		and state_machine.has_state(&"Climb")


## True if jump was pressed in the last few frames. Uses the press up.
func wants_to_jump() -> bool:
	if _buffer_left > 0.0:
		_buffer_left = 0.0
		return true
	return false


func start_jump() -> void:
	velocity.y = jump_velocity
	update_collision_shapes(true)
	$Jump.play()


func _keep_inside_camera() -> void:
	if not block_backtracking:
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var half_width := get_viewport_rect().size.x * 0.5 / cam.zoom.x
	var left_edge := cam.get_screen_center_position().x - half_width + 8.0
	if global_position.x < left_edge:
		global_position.x = left_edge
		velocity.x = maxf(velocity.x, 0.0)


# =============================================================================
# Collisions with the world (blocks, pipes)
# =============================================================================
func _handle_slide_collisions(input_dir: float) -> bool:
	var bump_target: Block = null
	var bump_distance := INF

	for i in get_slide_collision_count():
		var collision := get_slide_collision(i)
		var collider := collision.get_collider()
		var normal := collision.get_normal()

		# Landed on a switch-palace switch
		if collider is ColorSwitch and normal.y < -0.9:
			collider.press(self)

		# Head hit a block from below. If two blocks are above us, only bump the closest one.
		if collider is Block and normal.y > 0.9:
			var dx := absf((collider as Node2D).global_position.x - global_position.x)
			if dx < bump_distance:
				bump_distance = dx
				bump_target = collider as Block

		# Standing on top of a pipe + holding down
		if Input.is_action_pressed("down") and normal.y < -0.9:
			if collider is PipeD1 and _is_centered_on(collider):
				state_machine.transition_to(&"Pipe", {"offset": Vector2(0, 16), "done": scene_overD1_change, "pipe": collider})
				return true
			if collider is PipeD2 and _is_centered_on(collider):
				state_machine.transition_to(&"Pipe", {"offset": Vector2(0, 16), "done": scene_overD2_change, "pipe": collider})
				return true

		# Walking into a sideways pipe
		if collider is PipeSide and absf(normal.x) > 0.9 and signf(input_dir) == -signf(normal.x):
			state_machine.transition_to(&"Pipe", {"offset": Vector2(14 * -signf(normal.x), 0), "done": scene_under_change, "pipe": collider})
			return true

	if bump_target != null:
		bump_target.bump(player_mode)
	return false


func _is_centered_on(pipe: Node2D) -> bool:
	return absf(pipe.global_position.x - global_position.x) <= pipe_center_tolerance


# =============================================================================
# Touching enemies and pickups
# =============================================================================
func check_contacts() -> void:
	for body in area_2d.get_overlapping_bodies():
		if not _contacts_allowed():
			return
		if not is_instance_valid(body) or body.is_queued_for_deletion():
			continue
		_handle_contact(body)


func _contacts_allowed() -> bool:
	var st := state_machine.state
	return not is_dead and st != null and st.allows_contacts


func _handle_contact(body: Node2D) -> void:
	if body is Enemy:
		_handle_enemy_contact(body as Enemy)
	elif body is PowerUpItem:
		if body.can_collect():
			body.collected()
			give_power_up(body.power_up_id, body.global_position)
	elif body is Shroom:
		_collect_shroom(body)
	elif body is ShootingFlower:
		_collect_flower(body)
	elif body is SuperStar:
		_collect_star(body)
	elif body is LifeHeart:
		_collect_life(body)


func _handle_enemy_contact(enemy: Enemy) -> void:
	if not enemy.is_interactable():
		return

	if super_star_on:
		enemy.die_from_hit(float(facing_dir))
		return

	if enemy.can_be_stomped and state_machine.state.allows_stomp and _is_stomping(enemy):
		enemy.stomp(self)
		bounce_off_enemy()
		return

	enemy.touch_player(self)


func _is_stomping(enemy: Enemy) -> bool:
	var falling := velocity.y > 0.0 or (not is_on_floor() and velocity.y >= 0.0)
	if not falling:
		return false
	return get_feet_y() <= enemy.get_top_y() + stomp_tolerance


func get_feet_y() -> float:
	var shape := body_collision_shape.shape as RectangleShape2D
	var half_height := shape.size.y * 0.5 if shape else 4.0
	return body_collision_shape.global_position.y + half_height


## Called by enemies (and anything else you add) when Mario should bounce.
func bounce_off_enemy() -> void:
	velocity.y = stomp_bounce_held if Input.is_action_pressed("jump") else stomp_bounce
	update_collision_shapes(true)


## Called by anything that hurts Mario (enemy touch, piranha plant, explosion...).
func hurt(_source: Node = null) -> void:
	if is_dead or super_star_on or not can_take_damage:
		return
	if not state_machine.state.allows_damage:
		return
	if state_machine.state.on_hurt(_source):
		return
	if player_mode == PlayerMode.SMALL:
		die()
	else:
		$Powerdown.play()
		transform_to(PlayerMode.SMALL, true)


# =============================================================================
# Powerups
# =============================================================================
func _collect_shroom(item: Node) -> void:
	item.queue_free()
	give_power_up("mushroom", item.global_position)


func _collect_flower(item: Node) -> void:
	item.queue_free()
	give_power_up("superball", item.global_position)


## Gives Mario any power-up from Scripts/Player/PowerUps.gd by its id
## ("mushroom", "superball", "fire", "bunny", "speed_shoes" or your own).
func give_power_up(id: String, at_position: Vector2 = Vector2.INF) -> void:
	var data := PowerUps.get_data(id)
	if data.is_empty():
		push_warning("give_power_up: no power-up called '%s' in PowerUps.gd" % id)
		return
	_give_points(int(data.get("points", 1000)), global_position if at_position == Vector2.INF else at_position)
	if data.get("kind") == PowerUps.Kind.TIMED:
		$Powerup.play()
		match id:
			"speed_shoes":
				activate_speed_shoes(float(data.get("duration", 10.0)))
			_:
				activate_timed_power_up(id, float(data.get("duration", 10.0)))
		return
	var mode: int = data.get("mode", PlayerMode.BIG)
	if mode == player_mode:
		return                      # already have it: just the points
	if mode == PlayerMode.BIG and player_mode != PlayerMode.SMALL:
		return                      # a mushroom never takes a flower away
	$Powerup.play()
	transform_to(mode, false)


## Hook for your own TIMED power-ups: override or extend this (see the guide).
func activate_timed_power_up(id: String, _duration: float) -> void:
	push_warning("No timed effect written for power-up '%s' yet" % id)


# --- Speed shoes -------------------------------------------------------------
## Double speed for a while, with a ghost trail. Stacks with the star.
func activate_speed_shoes(duration: float) -> void:
	_shoes_token += 1
	var my_token := _shoes_token
	speed_shoes_on = true
	speed_multiplier = speed_shoes_multiplier
	await get_tree().create_timer(duration, false).timeout
	if my_token != _shoes_token or not is_instance_valid(self):
		return
	end_speed_shoes()


func end_speed_shoes() -> void:
	_shoes_token += 1
	speed_shoes_on = false
	speed_multiplier = 1.0


func _update_afterimages(delta: float) -> void:
	if not speed_shoes_on or absf(velocity.x) < 1.0:
		return
	_afterimage_left -= delta
	if _afterimage_left > 0.0:
		return
	_afterimage_left = afterimage_interval
	var frames: SpriteFrames = animated_sprite_2d.sprite_frames
	if frames == null or not frames.has_animation(animated_sprite_2d.animation):
		return
	var ghost := Sprite2D.new()
	ghost.texture = frames.get_frame_texture(animated_sprite_2d.animation, animated_sprite_2d.frame)
	ghost.flip_h = animated_sprite_2d.flip_h
	ghost.global_position = animated_sprite_2d.global_position
	ghost.modulate = Color(0.45, 0.65, 1.0, 0.55)
	ghost.z_index = z_index - 1
	get_tree().current_scene.add_child(ghost)
	var tween := ghost.create_tween()
	tween.tween_property(ghost, "modulate:a", 0.0, 0.25)
	tween.tween_callback(ghost.queue_free)


func _collect_star(item: Node) -> void:
	item.queue_free()
	_give_points(1000, item.global_position)
	activate_star(star_duration)


func _collect_life(item: Node) -> void:
	item.queue_free()
	GameManager.on_life_collected(1)
	_give_points(1000, item.global_position)
	$"1Up".play()


## Old name kept in case an old scene or script still calls it.
func handle_super_star_collision() -> void:
	activate_star(star_duration)


## Starts star power. duration <= 0 means "as long as the star song" (the default).
func activate_star(duration: float = -1.0) -> void:
	var song: AudioStreamPlayer = $"10Invincible(can-can)"
	if duration <= 0.0:
		duration = song.stream.get_length() if song.stream else 10.0
		if duration <= 0.0:
			duration = 10.0

	_star_token += 1            # a second star restarts the timer instead of stacking
	var my_token := _star_token
	super_star_on = true
	GameManager.superstar = true
	super_mode_play.emit()      # level scripts stop the level music on this
	song.play()

	_flash(star_flash_speed)
	# Second argument false = this timer pauses when the game is paused
	var warn_at := maxf(duration - star_warning_time, 0.0)
	await get_tree().create_timer(warn_at, false).timeout
	if my_token != _star_token:
		return
	_flash(star_flash_speed * 0.5)   # flash faster: star is about to run out
	await get_tree().create_timer(duration - warn_at, false).timeout
	if my_token != _star_token:
		return
	_end_star()


## Loops the sprite between see-through and solid. One tween instead of hundreds of lines.
func _flash(step_time: float) -> void:
	if _star_tween:
		_star_tween.kill()
	_star_tween = create_tween().set_loops()
	_star_tween.tween_property(animated_sprite_2d, "modulate:a", 0.25, step_time)
	_star_tween.tween_property(animated_sprite_2d, "modulate:a", 1.0, step_time)


func _end_star() -> void:
	_star_token += 1
	super_star_on = false
	GameManager.superstar = false
	if _star_tween:
		_star_tween.kill()
	animated_sprite_2d.modulate.a = 1.0
	$"10Invincible(can-can)".stop()
	super_mode_stop.emit()      # level scripts restart the level music on this


## Grow / shrink / get a flower. The Transform state plays the flicker.
func transform_to(new_mode: PlayerMode, is_damage: bool) -> void:
	if is_dead or state_machine.is_in(&"Transform"):
		return
	if not state_machine.state.allows_transform:
		return
	state_machine.transition_to(&"Transform", {"mode": new_mode, "damage": is_damage})


## Changes size instantly (no animation) and saves it for the next level.
func set_mode(new_mode: PlayerMode) -> void:
	player_mode = new_mode
	GameManager.player_mode = new_mode
	update_collision_shapes(false)
	apply_power_up_tint()


## Colours Mario's sprite for power-ups that don't have their own frames yet (PowerUps.gd "tint").
func apply_power_up_tint() -> void:
	animated_sprite_2d.self_modulate = PowerUps.for_mode(player_mode).get("tint", Color(1, 1, 1))


func idle_anim_for(mode: PlayerMode) -> String:
	if mode == PlayerMode.SMALL:
		return "small_idle"
	var data := PowerUps.for_mode(mode)
	var anim := "%s_idle" % data.get("anim_prefix", "big")
	if animated_sprite_2d.sprite_frames.has_animation(anim):
		return anim
	return "%s_idle" % data.get("fallback_prefix", "big")


## Blinks and can't be hurt for iframe_duration seconds (after shrinking).
func start_iframes() -> void:
	stop_iframes(false)
	can_take_damage = false
	_iframe_tween = create_tween().set_loops()
	_iframe_tween.tween_property(self, "modulate:a", 0.0, 0.1)
	_iframe_tween.tween_property(self, "modulate:a", 1.0, 0.1)
	# A timer (not await) so nothing is left waiting if Mario dies mid-blink
	_iframe_token += 1
	var my_token := _iframe_token
	get_tree().create_timer(iframe_duration, false).timeout.connect(func():
		if my_token == _iframe_token and is_instance_valid(self):
			stop_iframes())


func stop_iframes(reset_damage: bool = true) -> void:
	if _iframe_tween and _iframe_tween.is_valid():
		_iframe_tween.kill()
	if reset_damage:
		modulate.a = 1.0
		can_take_damage = true


# =============================================================================
# Superballs
# =============================================================================
func shoot() -> void:
	var path := current_projectile()
	if path == "":
		return
	if get_tree().get_nodes_in_group("superball").size() >= max_superballs:
		return
	_shoot_pose_left = 0.15
	var ball = (SUPERBALL_SCENE if path == SUPERBALL_SCENE.resource_path else load(path)).instantiate()
	ball.direction = facing_dir
	ball.global_position = global_position + Vector2(absf(shooting_point.position.x) * facing_dir, shooting_point.position.y)
	get_tree().current_scene.add_child(ball)


# =============================================================================
# Collision shape handling
# =============================================================================
func update_collision_shapes(is_jumping: bool = false) -> void:
	var shape: Shape2D
	if player_mode == PlayerMode.SMALL:
		shape = SMALL_JUMP_SHAPE if is_jumping else SMALL_SHAPE
	else:
		shape = BIG_SHAPE

	# Put the bottom of the shape on Mario's feet, whatever the shape's height is.
	var height := (shape as RectangleShape2D).size.y
	var offset := Vector2(0, FEET_Y - height * 0.5)

	body_collision_shape.set_deferred("shape", shape)
	body_collision_shape.set_deferred("position", offset)
	area_collision_shape.set_deferred("shape", shape)
	area_collision_shape.set_deferred("position", offset)


# =============================================================================
# Points
# =============================================================================
func _give_points(amount: int, at_position: Vector2) -> void:
	GameManager.on_points_scored(amount)
	spawn_points_label_bonus(amount, at_position)


func spawn_points_label_bonus(amount: int, at_position: Vector2 = Vector2.INF) -> void:
	var label = POINTS_LABEL_SCENE.instantiate()
	label.score = amount
	var base := global_position if at_position == Vector2.INF else at_position
	label.position = base + Vector2(-10, -25)
	get_tree().current_scene.add_child(label)


# =============================================================================
# Dying
# =============================================================================
## Kills Mario. instant = true for pits (ignores size and star). The Dead state does the rest.
func die(_instant: bool = false) -> void:
	if is_dead:
		return
	if super_star_on:
		_end_star()   # covers pits: they kill Mario whatever his size or star
	end_speed_shoes()
	state_machine.transition_to(&"Dead")


# =============================================================================
# Signal handlers your scenes are already connected to.
# (Level scenes connect DeathBox / coins / doors / piranha pipes straight to "Player".)
# =============================================================================
func _on_death_box_body_entered(body: Node2D) -> void:
	if body == self:
		die(true)


func _on_parana_plant_pipe_player_touched_paranha() -> void:
	hurt()


func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass   # contacts are polled every frame in check_contacts() instead


# The next few are connected in some level scenes. The coin / door / checkpoint scripts
# already do their own work, so these only exist to avoid "method not found" errors.
func _on_collectable_coin_19_body_entered(_body: Node2D) -> void:
	pass

func _on_collectable_coin_area_entered(_area: Area2D) -> void:
	pass

func _on_door_normal_area_entered(_area: Area2D) -> void:
	pass

func _on_area_2d_area_entered(_area: Area2D) -> void:
	pass

func _on_area_2d_area_enteredParahnaPlant(_area: Area2D) -> void:
	pass
