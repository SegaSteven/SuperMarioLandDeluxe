extends Enemy

class_name MekabonHead
## The head Mekabon throws. Flies out at Mario, slows to a stop, then flies straight back to
## the body (a boomerang). Can be stomped (100 points) or shot.

@export var throw_speed: float = 110.0
@export var return_accel: float = 220.0

var body: Node2D = null
var _returning: bool = false


func _init() -> void:
	score = 100


func _on_ready() -> void:
	always_active = true
	var p := get_player()
	var target := p.global_position if p else global_position + Vector2(-50, 0)
	velocity = global_position.direction_to(target) * throw_speed


func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY)
	collision_mask = 0


func _alive_physics(delta: float) -> void:
	if not is_instance_valid(body) or body.is_dead:
		queue_free()
		return
	var home := body.global_position + Vector2(0, -8)
	if not _returning:
		# Fly out, slowing down until it stops...
		var slowed := velocity.move_toward(Vector2.ZERO, return_accel * delta)
		if slowed.length() < 5.0 or slowed.dot(velocity) <= 0.0:
			_returning = true
		velocity = slowed
	else:
		# ...then speed straight back to the body
		velocity = velocity.move_toward(global_position.direction_to(home) * throw_speed, return_accel * 2.0 * delta)
		if global_position.distance_to(home) < 6.0:
			body.head_returned()
			queue_free()
			return
	global_position += velocity * delta


func _begin_death() -> void:
	super._begin_death()
	if is_instance_valid(body) and body.has_method("head_destroyed"):
		body.head_destroyed()
