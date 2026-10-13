extends Enemy

class_name Ganchan
## Ganchan (World 3): a boulder that falls and bounces along. It can't be destroyed - get out
## of the way. Drop them with an EnemySpawner, or have Hiyoihoi throw them.

@export var bounce_speed: float = 120.0
@export var roll_speed: float = 40.0
@export var max_bounces: int = 4

var launch_velocity: Vector2 = Vector2.ZERO
var _bounces: int = 0


func _on_ready() -> void:
	can_be_stomped = false
	immune_to_projectiles = true
	score = 0
	always_active = true
	if launch_velocity != Vector2.ZERO:
		velocity = launch_velocity
		direction = 1 if launch_velocity.x >= 0.0 else -1
		roll_speed = maxf(absf(launch_velocity.x), roll_speed)
	else:
		direction = direction_to_player()


func _alive_physics(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	velocity.x = direction * roll_speed
	move_and_slide()
	if is_on_floor():
		_bounces += 1
		velocity.y = -bounce_speed * (0.8 if _bounces > max_bounces else 1.0)
	if is_on_wall():
		direction = -direction


## Stars still smash it.
func die_from_hit(from_direction: float = 1.0) -> void:
	var p := get_player()
	if p and p.super_star_on:
		super.die_from_hit(from_direction)
