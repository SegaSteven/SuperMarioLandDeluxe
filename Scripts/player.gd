extends CharacterBody2D

class_name Player

signal points_scored(points: int)
signal scene_under_change
signal scene_overD1_change
signal scene_overD2_change
signal super_mode_play
signal super_mode_stop

var gravity = ProjectSettings.get_setting("physics/2d/default_gravity")

enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

#On Ready
const POINTS_LABEL_SCENE = preload("res://Scenes/points_label.tscn")
const FIREBALL_SCENE = preload("res://Scenes/fireball.tscn")
const SUPERBALL_SCENE = preload("res://Scenes/superball.tscn")
const PIPE_ENTER_THRESHOLD = 2

#jumping Collision shape stuff
#Big Mario
const BIG_MARIO_COLLISION_SHAPE_POSITION = Vector2(0, 8)
const BIG_MARIO_JUMP_COLLISION_SHAPE_POSITION = Vector2(0, 0)
const BIG_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Big_Mario_Collision_Shape_Normal.tres")
#Small Mario
const SMALL_MARIO_COLLISION_SHAPE_POSITION = Vector2(0, 5)
const SMALL_MARIO_JUMP_COLLISION_SHAPE_POSITION = Vector2(0, 2.5)
const SMALL_MARIO_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Small_Mario_Collision_Shape_Normal.tres")
const SMALL_MARIO_JUMP_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Small_Mario_Jump_Collision_Shape.tres")
const BIG_MARIO_JUMP_COLLISION_SHAPE = preload("res://Resources/CollisionShapes/Big_Mario_Collision_Shape_Normal.tres")

@onready var mario_jump_area_collision = $Area2D/AreaCollisionShape
@onready var mario_jump_body_collision = $BodyCollisionShape

#variable gravity
const GravityJump = 350
const GravityFall = 360

#References
@onready var animated_sprite_2d = $AnimatedSprite2D
@onready var area_2d = $Area2D
@onready var area_collision_shape = $Area2D/AreaCollisionShape
@onready var body_collision_shape = $BodyCollisionShape
@onready var enemy_script = preload("res://Scripts/enemy.gd")
@onready var shroom_script = preload("res://Scripts/shroom.gd")
@onready var shooting_flower = preload("res://Scripts/shooting_flower.gd")
@onready var shooting_point = $AnimatedSprite2D/ShootingPoint

@export_group("Locomotion")
@export var run_speed_damping = 0.5
@export var speed = 118.0
@export var jump_velocity = -155
@export var max_walk_speed: float = 64
@export var max_run_speed: float = 80
@export var max_sprint_speed: float = 180
@export var walk_accel: float = 337.5
@export var stop_decel: float = 1000
@export_group("")

@export_group("stomping enemies")
@export var min_stomp_degree = 40
@export var max_stomp_degree = 120
@export var stomp_y_veloclity = -150
@export_group("")

var facing_dir = -1

var bounce_mode = true
var shooting = false

var player_mode = PlayerMode.SMALL
var can_take_damage = true
var super_star_on = false

var enemy = Enemy
var shroom = Shroom
var player = Player

#Player State flags
var is_dead = false

func _ready():
	GameManager.player = self
	self.add_to_group("player")
	player_mode = GameManager.player_mode
	
	
	gravity = GravityJump
	
	if GameManager.spawn_point != null && GameManager.spawn_point != Vector2.ZERO:
		global_position = GameManager.spawn_point
		
	if player_mode == PlayerMode.SMALL && is_on_floor():
		mario_jump_area_collision.set_deferred("shape", SMALL_MARIO_COLLISION_SHAPE)
		mario_jump_body_collision.set_deferred("shape", SMALL_MARIO_COLLISION_SHAPE)
		mario_jump_area_collision.set_deferred("position", SMALL_MARIO_COLLISION_SHAPE_POSITION)
		mario_jump_body_collision.set_deferred("position", SMALL_MARIO_COLLISION_SHAPE_POSITION)
	
	if player_mode == PlayerMode.BIG && is_on_floor():
		mario_jump_area_collision.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
		mario_jump_body_collision.set_deferred("shape", BIG_MARIO_COLLISION_SHAPE)
		mario_jump_area_collision.set_deferred("position", BIG_MARIO_COLLISION_SHAPE_POSITION)
		mario_jump_body_collision.set_deferred("position", BIG_MARIO_COLLISION_SHAPE_POSITION)

func HandleGravity(delta, gravity: float = GravityJump):
	if (!is_on_floor()):
		velocity.y += gravity * delta

func _physics_process(delta):
	
	#var camera_left_bound = camera_sync.global_position.x - camera_sync.get_viewport_rect().size.x / 2 / camera_sync.zoom.x	
	
	if is_on_floor() and bounce_mode == false:
		bounce_mode = true
	
	# Apply gravity
	if not is_on_floor():
		gravity = GravityJump
		velocity.y += gravity * delta
	
	#if global_position.x < camera_left_bound + 8 && sign(velocity.x) == -1:
		#velocity = Vector2(0,0)
		#return
	
# Handle jumps
# jumping - SMALL
	if Input.is_action_just_pressed("jump") and is_on_floor() && player_mode == PlayerMode.SMALL:
		mario_jump_area_collision.set_deferred("shape", SMALL_MARIO_JUMP_COLLISION_SHAPE)
		mario_jump_body_collision.set_deferred("shape", SMALL_MARIO_JUMP_COLLISION_SHAPE)
		mario_jump_area_collision.set_deferred("position", SMALL_MARIO_JUMP_COLLISION_SHAPE_POSITION)
		mario_jump_body_collision.set_deferred("position", SMALL_MARIO_JUMP_COLLISION_SHAPE_POSITION)
		velocity.y = jump_velocity
		$Jump.play()
		
		
	# jumping - BIG
	if Input.is_action_just_pressed("jump") and is_on_floor() && player_mode == PlayerMode.BIG:
		mario_jump_area_collision.set_deferred("shape", BIG_MARIO_JUMP_COLLISION_SHAPE)
		mario_jump_body_collision.set_deferred("shape", BIG_MARIO_JUMP_COLLISION_SHAPE)
		mario_jump_area_collision.set_deferred("position", BIG_MARIO_JUMP_COLLISION_SHAPE_POSITION)
		mario_jump_body_collision.set_deferred("position", BIG_MARIO_JUMP_COLLISION_SHAPE_POSITION)
		velocity.y = jump_velocity
		$Jump.play()
		
	# jumping - SHOOTING
	if Input.is_action_just_pressed("jump") and is_on_floor() && player_mode == PlayerMode.SHOOTING:
		mario_jump_area_collision.set_deferred("shape", BIG_MARIO_JUMP_COLLISION_SHAPE)
		mario_jump_body_collision.set_deferred("shape", BIG_MARIO_JUMP_COLLISION_SHAPE)
		mario_jump_area_collision.set_deferred("position", BIG_MARIO_JUMP_COLLISION_SHAPE_POSITION)
		mario_jump_body_collision.set_deferred("position", BIG_MARIO_JUMP_COLLISION_SHAPE_POSITION)
		velocity.y = jump_velocity
		$Jump.play()
		

		
	if Input.is_action_pressed("down") && player_mode == PlayerMode.BIG && PlayerMode.SHOOTING:
		@warning_ignore("standalone_expression")
		PlayerAnimatedSprite
		
	if !is_on_floor() and velocity.y >= 0:
		HandleGravity(delta, GravityFall)
		
	if Input.is_action_just_released("jump") and velocity.y < 0:
		velocity.y *= 0.8
		
	if Input.is_action_pressed("action") and velocity.y < 0 and velocity.x > 20:
		velocity.y += -1.01
		
	if Input.is_action_pressed("action") and velocity.y < 0 and velocity.x < -20:
		velocity.y += -1.01
	
	#Handle axis movement ------------------------------------------------------
	var direction = Input.get_axis("left", "right")
	
	#Handle Spriting -----------------------------------------------------------
	if direction:
		var max_speed: float = max_walk_speed
		if Input.is_action_pressed("action"):
			max_speed = max_run_speed
		
		velocity.x = move_toward(velocity.x, direction * max_speed, walk_accel * delta)
		facing_dir = direction
	else:
		velocity.x = move_toward(velocity.x, 0, stop_decel * delta)
	
	if velocity.x >= 0:
		animated_sprite_2d.speed_scale = abs(velocity.x * 0.03)
	if velocity.x <= 0:
		animated_sprite_2d.speed_scale = (velocity.x * 0.03)
		
	
		
	var collision = get_last_slide_collision()
	if collision != null:
		handle_movement_collision(collision)
		
	move_and_slide()
	
	if Input.is_action_just_pressed("action") && player_mode == PlayerMode.SHOOTING:
		if not shooting:
			shoot()
			shooting = true
			await get_tree().create_timer(1).timeout
			shooting = false
			
	animated_sprite_2d.trigger_animation(velocity, direction, player_mode)
	
func player_update():
	if GameManager.player_mode == PlayerMode.SMALL:
		return
	elif GameManager.player_mode == PlayerMode.BIG:
		player_mode = GameManager.player_mode
	else:
		player_mode = PlayerMode.SHOOTING

func _on_area_2d_area_entered(area: Area2D):
	if area is Enemy:
		handle_enemy_collision(area)
	if area is Shroom:
		handle_shroom_collision(area)
		spawn_points_label_bonus(1000)
		GameManager.on_points_scored(1000)
		area.queue_free()
	if area is ShootingFlower:
		handle_flower_collsion(area)
		spawn_points_label_bonus(1000)
		GameManager.on_points_scored(1000)
		area.queue_free()
	if area is LifeHeart:
		spawn_points_label_bonus(1000)
		GameManager.on_points_scored(1000)
		$"1Up".play()
	#if area is SuperStar:
		#spawn_points_label_bonus(1000)
		#handle_super_star_collision(area)
		#area.queue_free()
		
@warning_ignore("shadowed_variable")
func handle_enemy_collision(enemy: Enemy):
	if enemy == null && is_dead:
		return
		
	if super_star_on == true:
		enemy.die_from_hit()
		spawn_points_label(enemy)
		
	var angle_of_collision = rad_to_deg(position.angle_to_point(enemy.position))
		
	if angle_of_collision > min_stomp_degree && max_stomp_degree > angle_of_collision:
		enemy.die()
		on_enemy_stomped()
		spawn_points_label(enemy)
	else:
		if can_take_damage == true:
			die()
		
func iframes():
	can_take_damage = false
	await get_tree().create_timer(2).timeout
	can_take_damage = true
	
@warning_ignore("unused_parameter")
func handle_super_star_collision():
		super_mode_play.emit()
		$"10Invincible(can-can)".play()
		can_take_damage = false
		super_star_on = true
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		super_mode_stop.emit()
		can_take_damage = true
		super_star_on = false
		
@warning_ignore("unused_parameter")
func handle_shroom_collision(area: Node2D):
	if player_mode == PlayerMode.SMALL:
		$Powerup.play()
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		
func handle_flower_collsion(area: Node2D):
	if player_mode == PlayerMode.BIG:
		GameManager.on_points_scored(1000)
		$Powerup.play()
		self.player_mode = PlayerMode.SHOOTING
		area.queue_free()
	if player_mode == PlayerMode.SMALL:
		area.queue_redraw()
		
func handle_movement_collision(collision: KinematicCollision2D):
	if collision.get_collider() is Block:
		var collision_angle = rad_to_deg(collision.get_angle())
		if roundf(collision_angle) == 180:
			(collision.get_collider() as Block).bump(player_mode)
	
	if collision.get_collider() is PipeD1:
		#var collision_angle = rad_to_deg(collision.get_angle())
		#if roundf(collision_angle) == 0 && Input.is_action_just_pressed("down") && absf(collision.get_collider().position.x - position.x < PIPE_ENTER_THRESHOLD && collision.get_collider().is_traversable):
		if Input.is_action_just_pressed("down"):
			handle_pipeD1_collision()
			
	if collision.get_collider() is PipeD2:
		#var collision_angle = rad_to_deg(collision.get_angle())
		#if roundf(collision_angle) == 0 && Input.is_action_just_pressed("down") && absf(collision.get_collider().position.x - position.x < PIPE_ENTER_THRESHOLD && collision.get_collider().is_traversable):
		if Input.is_action_just_pressed("down"):
			handle_pipeD2_collision()
		
	if collision.get_collider() is PipeSide:
		handle_side_pipe_enterance_collision()
		
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

func on_enemy_stomped():
	if bounce_mode == true:
		velocity.y = stomp_y_veloclity
		bounce_mode = false
		
func die():
	var level_manager = get_tree().get_first_node_in_group("level_manager")
	if player_mode == PlayerMode.SMALL:
		is_dead = true
		animated_sprite_2d.play("death")

		set_physics_process(false)
		
		area_2d.set_collision_mask_value(3, false)
		set_collision_layer_value(1, false)
		$"../LevelMusic".stop()
		$"11LoseLife".play()
		GameManager.lose_life(-1)
		var death_tween = get_tree().create_tween()
		death_tween.tween_property(self, "position", position + Vector2(0, -44), .5)
		death_tween.chain().tween_property(self, "position", position + Vector2(0, 200), 1.2).finished
		await death_tween.finished
		get_tree().call_deferred("reload_current_scene")
	else:
		iframes()
		$Powerdown.play()
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.BIG
		await get_tree().create_timer(.05).timeout
		self.player_mode = Player.PlayerMode.SMALL
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 0.0
		await get_tree().create_timer(0.1).timeout
		modulate.a = 1.0
		
	#if player_mode == PlayerMode.SMALL and GameManager.lives == 0:
		#get_tree().change_scene_to_file("res://Scenes/title_screen.tscn")
		

func get_input():
	# Add these actions in Project Settings -> Input Map.
	var input_dir = Input.get_axis("left", "right")
	velocity = transform.x * input_dir * speed
	if Input.is_action_just_pressed("shoot"):
		shoot()

func shoot():
	animated_sprite_2d.play("shoot")
	
	var superball = SUPERBALL_SCENE.instantiate()
	superball.direction = sign(animated_sprite_2d.scale.x)
	superball.global_position = shooting_point.global_position
	get_tree().root.add_child(superball)

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


func _on_death_box_body_entered(body: Node2D):
	die()


func _on_body_entered(body: CollectableCoin):
	$Coin.play()


func _on_area_2d_body_entered(body: SuperStar):
		spawn_points_label_bonus(1000)
		handle_super_star_collision()


func _on_parana_plant_pipe_player_touched_paranha() -> void:
	die()
