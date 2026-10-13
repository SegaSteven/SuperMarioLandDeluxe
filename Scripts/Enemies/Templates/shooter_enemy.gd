extends Enemy

class_name ShooterEnemy
## A ready-made enemy that SHOOTS. Tune in the Inspector:
##   Gao (statue)         : movement NONE, aim AT_PLAYER
##   Nyololin (snake)     : movement NONE, aim ALL_DIRECTIONS, shot_count 8, shots go through walls
##   Pompon Flower        : movement NONE, aim UP_ARC (spores lobbed up and over)
##   Yurarin Boo (seahorse): movement DRIFT_TO_PLAYER, aim AT_PLAYER
##   Roketon (plane)      : movement FLY_LEFT, aim FORWARD
## The shot is any scene using BossProjectile (e.g. res://Scenes/Enemies/Bosses/boss_fireball.tscn).

enum Movement { NONE, WALK, FLY_LEFT, DRIFT_TO_PLAYER, BOB }
enum Aim { AT_PLAYER, FORWARD, BOTH_SIDES, ALL_DIRECTIONS, UP_ARC }

@export_group("Shooting")
@export var projectile_scene: PackedScene = preload("res://Scenes/Enemies/Bosses/boss_fireball.tscn")
@export var aim: Aim = Aim.AT_PLAYER
@export var fire_interval: float = 2.0
@export var first_shot_delay: float = 1.0
@export var shot_count: int = 8               ## for ALL_DIRECTIONS
@export var shot_speed: float = 60.0
@export var arc_up_speed: float = 120.0       ## for UP_ARC
@export var arc_gravity: float = 200.0        ## for UP_ARC
@export var fire_offset: Vector2 = Vector2(0, -2)
@export var only_when_player_near: float = 0.0   ## > 0 = only shoots when Mario is this close

@export_group("Moving")
@export var movement: Movement = Movement.NONE
@export var move_speed: float = 20.0
@export var bob_height: float = 6.0

@export_group("Animations")
@export var anim_idle: StringName = &"default"
@export var anim_shoot: StringName = &"shoot"

var _fire_left: float
var _t: float = 0.0
var _origin: Vector2


func _on_ready() -> void:
	_fire_left = first_shot_delay
	_origin = global_position
	_play_anim(anim_idle)


func _alive_physics(delta: float) -> void:
	_t += delta
	match movement:
		Movement.NONE:
			apply_gravity(delta)
			velocity.x = 0.0
			move_and_slide()
		Movement.WALK:
			super._alive_physics(delta)
		Movement.FLY_LEFT:
			global_position.x -= move_speed * delta
			global_position.y = _origin.y + sin(_t * 3.0) * bob_height
		Movement.DRIFT_TO_PLAYER:
			var p := get_player()
			if p:
				global_position += global_position.direction_to(p.global_position) * move_speed * delta
		Movement.BOB:
			global_position.y = _origin.y + sin(_t * 2.0) * bob_height

	if movement != Movement.WALK and movement != Movement.FLY_LEFT:
		_face(direction_to_player())

	_fire_left -= delta
	if _fire_left <= 0.0:
		_fire_left = fire_interval
		var p2 := get_player()
		if only_when_player_near <= 0.0 or (p2 and p2.global_position.distance_to(global_position) <= only_when_player_near):
			fire()


func fire() -> void:
	if projectile_scene == null or not is_inside_tree():
		return
	var p := get_player()
	var dir := direction_to_player()
	var velocities: Array[Vector2] = []
	match aim:
		Aim.AT_PLAYER:
			if p:
				velocities.append(global_position.direction_to(p.global_position) * shot_speed)
		Aim.FORWARD:
			velocities.append(Vector2(direction * shot_speed, 0))
		Aim.BOTH_SIDES:
			velocities.append(Vector2(shot_speed, 0))
			velocities.append(Vector2(-shot_speed, 0))
		Aim.ALL_DIRECTIONS:
			for i in shot_count:
				velocities.append(Vector2.RIGHT.rotated(TAU * i / shot_count) * shot_speed)
		Aim.UP_ARC:
			velocities.append(Vector2(dir * shot_speed * 0.5, -arc_up_speed))
	for v in velocities:
		var shot = projectile_scene.instantiate()
		shot.global_position = global_position + fire_offset
		if "launch_velocity" in shot:
			shot.launch_velocity = v
		if "direction" in shot:
			shot.direction = 1 if v.x >= 0.0 else -1
		if aim == Aim.UP_ARC and "arc_gravity" in shot:
			shot.arc_gravity = arc_gravity
		get_tree().current_scene.add_child(shot)
	_play_anim(anim_shoot)
	_play_sfx("Fire")
	get_tree().create_timer(0.3, false).timeout.connect(func():
		if is_instance_valid(self) and not is_dead: _play_anim(anim_idle))


## Flying shooters fall out of the sky when stomped.
func stomp(_player: Node) -> void:
	if movement == Movement.FLY_LEFT or movement == Movement.DRIFT_TO_PLAYER or movement == Movement.BOB:
		die_from_hit(0.0)
	else:
		super.stomp(_player)


