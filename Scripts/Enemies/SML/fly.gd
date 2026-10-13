extends Enemy

class_name Fly
## Fly: sits for a moment, then hops towards Mario. Every few small hops it does a big one.

@export var hop_wait: float = 0.6
@export var small_hop_speed: float = 90.0
@export var big_hop_speed: float = 170.0
@export var small_hops_before_big: int = 2
@export var air_speed: float = 20.0

var _wait_left: float = 0.0
var _hops_done: int = 0


func _init() -> void:
	score = 400   # default; the Inspector can still change it


func _on_ready() -> void:
	_wait_left = hop_wait
	_play_anim("default")


func _alive_physics(delta: float) -> void:
	apply_gravity(delta)

	if is_on_floor():
		velocity.x = 0.0
		_play_anim("default")
		_wait_left -= delta
		if _wait_left <= 0.0:
			_hop()
	move_and_slide()

	if not is_on_floor() and is_on_wall():
		direction = -direction
		velocity.x = direction * air_speed
		_face(direction)


func _hop() -> void:
	direction = direction_to_player()
	_face(direction)
	var big := _hops_done >= small_hops_before_big
	velocity.y = -(big_hop_speed if big else small_hop_speed)
	velocity.x = direction * air_speed
	_hops_done = 0 if big else _hops_done + 1
	_wait_left = hop_wait
	_play_anim("jump")
