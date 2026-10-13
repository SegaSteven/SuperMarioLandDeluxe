extends Enemy

class_name BossProjectile
## Any enemy's shot (fireball, spore, rock, bullet). Despite the name it's used by normal
## enemies too. A boss's fireball / rock / spear. Hurts Mario, can't be stomped, superballs pass through.
## The boss sets `direction` before adding it. Set `aim_at` (or tick aim_at_player on the boss's
## shoot_projectile call) to fire it straight at a point instead.

@export var speed: float = 70.0
@export var arc_gravity: float = 0.0          ## > 0 makes it fall in an arc (thrown rock)
@export var throw_up_speed: float = 0.0       ## upward speed at launch for arcs
@export var pass_through_walls: bool = true
@export var lifetime: float = 6.0

var aim_at: Vector2 = Vector2.INF
## Set before adding to the scene to fire in an exact direction/speed (spread shots, throws).
var launch_velocity: Vector2 = Vector2.ZERO


func _on_ready() -> void:
	can_be_stomped = false
	immune_to_projectiles = true
	always_active = true
	score = 0
	if launch_velocity != Vector2.ZERO:
		velocity = launch_velocity
	elif aim_at != Vector2.INF:
		velocity = global_position.direction_to(aim_at) * speed
	else:
		velocity = Vector2(direction * speed, -throw_up_speed)
	_face(direction)
	_play_sfx("Fire")
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY)
	collision_mask = 0 if pass_through_walls else Layers.WORLD_MASK


func _alive_physics(delta: float) -> void:
	velocity.y += arc_gravity * delta
	if pass_through_walls:
		global_position += velocity * delta
	else:
		move_and_slide()
		if get_slide_collision_count() > 0:
			queue_free()
	if absf(global_position.x - _camera_x()) > 300.0:
		queue_free()


func _camera_x() -> float:
	var cam := get_viewport().get_camera_2d()
	return cam.get_screen_center_position().x if cam else global_position.x
