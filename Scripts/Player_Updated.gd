extends CharacterBody2D

class_name PlayerUpdated

# Signals
signal points_scored(points: int)
signal scene_under_change
signal scene_overD1_change
signal scene_overD2_change
signal super_mode_play
signal super_mode_stop

# Enums & Constants
enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}
const POINTS_LABEL_SCENE = preload("res://Scenes/points_label.tscn")
const SUPERBALL_SCENE = preload("res://Scenes/superball.tscn")

# Collision Shape Resources
const SMALL_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Small_Mario_Collision_Shape_Normal.tres")
const BIG_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Big_Mario_Collision_Shape_Normal.tres")
const SMALL_MARIO_JUMP_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Small_Mario_Jump_Collision_Shape.tres")

# Physics Constants (Tuned for GameBoy feel)
const GravityJump = 350
const GravityFall = 500 # Increased for better "weight" when falling
@export var walk_accel: float = 800.0 # Increased for snappier movement
@export var stop_decel: float = 1000
@export var max_walk_speed: float = 60
@export var max_run_speed: float = 120
@export var jump_velocity = -180.0
@export var stomp_y_veloclity = -150

# State Variables
var player_mode = PlayerMode.SMALL
var can_take_damage = true
var super_star_on = false
var is_dead = false
var shooting = false
var facing_dir = 1

@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var body_collision_shape = $BodyCollisionShape
@onready var shooting_point = $AnimatedSprite2D/ShootingPoint

func _ready():
	# 'self' refers to this specific player instance
	GameManager.player = self 
	
	# Safely load the mode from the manager
	player_mode = GameManager.player_mode
	
	# Initialize the correct hitbox
	update_collision_shapes()
	
	print("Player registered to GameManager successfully!")

func _physics_process(delta):
	var input_dir = Input.get_axis("left", "right")
	animated_sprite_2d.trigger_animation(velocity, input_dir, player_mode)
	
	if is_dead: return

	apply_gravity(delta)
	handle_jump()
	handle_movement(delta)
	
	# move_and_slide uses the 'velocity' property automatically
	move_and_slide()
	
	# Process collisions with blocks/pipes (Physical hits)
	for i in get_slide_collision_count():
		var collision = get_slide_collision(i)
		handle_movement_collision(collision)

func handle_shooting():
	animated_sprite_2d.trigger_animation(velocity, Input.get_axis("left", "right"), player_mode)

func apply_gravity(delta):
	if not is_on_floor():
		var current_gravity = GravityFall if velocity.y > 0 else GravityJump
		velocity.y += current_gravity * delta

func handle_jump():
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity
		$Jump.play()
		update_collision_shapes(true) # Switch to jump shape
	
	# Variable jump height (Hold for higher, release for lower)
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.5 

	if is_on_floor() and velocity.y >= 0:
		update_collision_shapes(false) # Return to normal shape

func handle_movement(delta):
	var direction = Input.get_axis("left", "right")
	var current_max_speed = max_run_speed if Input.is_action_pressed("action") else max_walk_speed
	
	if direction:
		velocity.x = move_toward(velocity.x, direction * current_max_speed, walk_accel * delta)
		# Flip sprite based on direction
		animated_sprite_2d.flip_h = (direction < 0)
	else:
		velocity.x = move_toward(velocity.x, 0, stop_decel * delta)

func handle_movement_collision(collision: KinematicCollision2D):
	var collider = collision.get_collider()
	
	if collider is Block:
		# get_normal() returns the direction the collider is pushing Mario.
		# If Mario hits his head, the block pushes DOWN.
		var normal = collision.get_normal()
		
		# In Godot, Vector2.DOWN is (0, 1). 
		# We check if the normal is mostly pointing down.
		if normal.dot(Vector2.DOWN) > 0.9: 
			collider.bump(player_mode)

	# 2. Entering Pipes
	if Input.is_action_pressed("down") and is_on_floor():
		if collider is PipeD1: switch_to_pipe_tween(Vector2(0, 16), switch_to_undergroundD1)
		if collider is PipeD2: switch_to_pipe_tween(Vector2(0, 16), switch_to_undergroundD2)

func update_collision_shapes(is_jumping: bool = false):
	var shape_to_use
	var target_y_offset: float = 0.0

	if player_mode == PlayerMode.SMALL:
		shape_to_use = SMALL_MARIO_JUMP_COLLISION_SHAPE if is_jumping else SMALL_MARIO_COLLISION_SHAPE
		# Move the center of the shape UP (more negative) 
		# so the bottom of the shape is at Mario's feet.
		target_y_offset = -7.0 
	else:
		shape_to_use = BIG_MARIO_COLLISION_SHAPE
		target_y_offset = -15.0

	body_collision_shape.set_deferred("shape", shape_to_use)
	body_collision_shape.set_deferred("position", Vector2(0, target_y_offset))

# Hitbox logic (For Enemies/Powerups)
func _on_area_2d_body_entered(body: Node2D):
	if body is Enemy:
		# Check if Mario is falling onto the enemy (Stomp)
		if velocity.y > 0 and global_position.y < body.global_position.y:
			body.die()
			velocity.y = stomp_y_veloclity
			spawn_points_label(body)
		elif can_take_damage:
			if super_star_on:
				body.die_from_hit()
			else:
				die()
	
	if body is Shroom:
		handle_shroom_logic()
		body.queue_free()

func handle_shroom_logic():
	# Use 'self.player_mode' to be explicit if needed
	if player_mode == PlayerMode.SMALL:
		# 1. Update State
		player_mode = PlayerMode.BIG  # Ensure this variable is 'var player_mode' at the top
		GameManager.player_mode = self.player_mode
		
		# 2. Play Sound
		if has_node("Powerup"):
			$Powerup.play()
		
		# 3. Animation
		animate_growth()
		
		# 3. Handle Score
		spawn_points_label_bonus(1000)
		GameManager.on_points_scored(1000)
		
		# 4. Trigger the Grow Animation & Hitbox Change
		animate_growth()
	else:
		# If already Big/Shooting, just give points
		spawn_points_label_bonus(1000)
		GameManager.on_points_scored(1000)


func animate_growth():
	# 1. Prevent overlapping growth calls
	if not is_physics_processing():
		return
		
	# 2. Freeze Mario in place
	# We turn off physics processing so he doesn't walk/fall while growing
	set_physics_process(false)
	
	# 3. Create the "Stutter" effect
	var grow_tween = get_tree().create_tween()
	
	# Loop the visual change 4 times (Small -> Big -> Small)
	for i in range(4):
		grow_tween.tween_callback(func(): animated_sprite_2d.play("big_idle"))
		grow_tween.tween_interval(0.1)
		grow_tween.tween_callback(func(): animated_sprite_2d.play("small_idle"))
		grow_tween.tween_interval(0.1)
	
	# 4. Finalize the Growth
	grow_tween.tween_callback(finalize_growth)

func finalize_growth():
	# Update the actual mode
	player_mode = PlayerMode.BIG
	
	# Play the final animation
	animated_sprite_2d.play("big_idle")
	
	# Update the CharacterBody2D collision shape to the BIG version
	update_collision_shapes(false) 
	
	# Re-enable the physics switch
	set_physics_process(true)

func spawn_points_label(enemy):
	var points_label = POINTS_LABEL_SCENE.instantiate()
	points_label.score = enemy.score
	if get_tree().has_group("koopabomb"):
		queue_free()
	else:
		points_label.position = enemy.position + Vector2(-10, -25)
		get_tree().root.add_child(points_label)

func spawn_points_label_bonus(bonus):
	var points_label = POINTS_LABEL_SCENE.instantiate()
	points_label.score = bonus
	points_label.position = self.position + Vector2(-10, -25)
	get_tree().root.add_child(points_label)

func die():
	if not can_take_damage: return
	if player_mode != PlayerMode.SMALL:
		# Shrink logic
		player_mode = PlayerMode.SMALL
		update_collision_shapes()
		start_iframes()
		$Powerdown.play()
	else:
		is_dead = true
		set_physics_process(false)
		animated_sprite_2d.play("death")
		# Tween death animation... (keeping your existing logic)
		var death_tween = get_tree().create_tween()
		death_tween.tween_property(self, "position", position + Vector2(0, -44), .5)
		death_tween.tween_property(self, "position", position + Vector2(0, 200), 1.2)
		await death_tween.finished
		get_tree().reload_current_scene()

func start_iframes():
	can_take_damage = false
	var blink = get_tree().create_tween().set_loops(10)
	blink.tween_property(self, "modulate:a", 0.0, 0.1)
	blink.tween_property(self, "modulate:a", 1.0, 0.1)
	await blink.finished
	can_take_damage = true

# Helper for pipe transitions
func switch_to_pipe_tween(offset: Vector2, callback: Callable):
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + offset, 1.0)
	pipe_tween.tween_callback(callback)
	
# PIPE DATA FOR PIPE DOWN NO 1 -----------------------------------------------
func handle_pipeD1_collision():
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(0, 16), 1)
	pipe_tween.tween_callback(switch_to_undergroundD1)
	
	
func switch_to_undergroundD1():
	GameManager.player_mode = player_mode
	emit_signal("scene_overD1_change")

# PIPE DATA FOR PIPE DOWN NO 2 -----------------------------------------------
func handle_pipeD2_collision():
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(0, 16), 1)
	pipe_tween.tween_callback(switch_to_undergroundD2)
	
	
func switch_to_undergroundD2():
	GameManager.player_mode = player_mode
	emit_signal("scene_overD2_change")

# PIPE DATA FOR PIPE SIDE ----------------------------------------------------
func handle_side_pipe_enterance_collision():
	set_physics_process(false)
	var pipe_tween = get_tree().create_tween()
	pipe_tween.tween_property(self, "position", position + Vector2(14, 0), 1)
	pipe_tween.tween_callback(switch_to_overground)
#
func switch_to_overground():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	GameManager.player_mode = player_mode
	emit_signal("scene_under_change")
