extends Enemy

class_name Ganchan
## Ganchan (Easton Kingdom): a boulder that falls and bounces along. It can't be destroyed
## (only a star smashes it). Drop them with an EnemySpawner, or have Hiyoihoi (the Easton boss)
## throw them - his are this same scene, so they work the same way.
##   - ENEMY: touching its side hurts Mario.
##   - PLATFORM: it's solid on top - Mario can stand on it and ride it as it rolls and bounces.
##   - CRUSH: if it comes down on Mario from above, it hurts him (or kills him outright with
##     Crush Kills).

@export var bounce_speed: float = 120.0
@export var roll_speed: float = 40.0
@export var max_bounces: int = 4

@export_group("Platform and crushing")
## Mario can stand on it and gets carried along.
@export var rideable: bool = true
## Touching its side hurts Mario (untick for a harmless rolling platform).
@export var side_hurts: bool = true
## Landing on Mario kills him whatever his size (otherwise it hurts him like any enemy).
@export var crush_kills: bool = false
@export_group("")

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


## Solid for Mario too (so he can stand on it); it still only bumps into the world itself.
func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY) | (Layers.bit(Layers.OBSTACLE) if rideable else 0)
	collision_mask = Layers.WORLD_MASK


func _alive_physics(delta: float) -> void:
	velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	velocity.x = direction * roll_speed
	move_and_slide()
	if is_on_floor():
		_bounces += 1
		velocity.y = -bounce_speed * (0.8 if _bounces > max_bounces else 1.0)
	if is_on_wall():
		direction = -direction
	# (Mario standing on it is carried along by Godot, like on any moving floor)
	_check_player_contact()


## Being solid, the boulder can push Mario aside before his hitbox touches it, so it checks
## for contact itself: touching from the side or underneath = touch_player().
func _check_player_contact() -> void:
	var p := get_player() as PlayerUpdated
	if p == null or p.is_dead or not is_interactable():
		return
	var cs: CollisionShape2D = p.body_collision_shape
	var pr := Rect2(p.global_position - Vector2(4, 8), Vector2(8, 16))
	if cs and cs.shape:
		var r := cs.shape.get_rect()
		pr = Rect2(cs.global_position + r.position, r.size)
	var me := Rect2(global_position - _half_size(), _half_size() * 2.0).grow(1.5)
	if me.intersects(pr):
		touch_player(p)


## Half the boulder's size (from its collision shape).
func _half_size() -> Vector2:
	if body_shape and body_shape.shape:
		return body_shape.shape.get_rect().size * 0.5
	return Vector2(6, 6)


func _top_y() -> float:
	return global_position.y - _half_size().y


## Mario, if he's standing on top of it right now.
func _rider() -> PlayerUpdated:
	if not rideable:
		return null
	var p := get_player() as PlayerUpdated
	if p == null or p.is_dead or not p.is_on_floor():
		return null
	if absf(p.global_position.x - global_position.x) > _half_size().x + 6.0:
		return null
	if absf(p.get_feet_y() - _top_y()) > 3.0:
		return null
	return p


func touch_player(player: Node) -> void:
	var p := player as PlayerUpdated
	if p == null:
		return
	if rideable and p.get_feet_y() <= _top_y() + 3.0:
		return                                   # standing / landing on top: safe
	var crushing := velocity.y > 0.0 and p.global_position.y > global_position.y
	if crushing:
		if crush_kills:
			p.die(true)
		else:
			p.hurt(self)
	elif side_hurts:
		p.hurt(self)


## Stars still smash it.
func die_from_hit(from_direction: float = 1.0) -> void:
	var p := get_player()
	if p and p.super_star_on:
		super.die_from_hit(from_direction)
