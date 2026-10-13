extends Enemy

class_name Honen
## Honen (World 2, Muda): a skeleton fish that leaps straight up out of the water at regular
## intervals, then drops back down. Place it just below the water surface.
## Stomp it, or hit it with a torpedo. Superballs pass straight through.

@export var leap_speed: float = 180.0
@export var leap_interval: float = 2.0
@export var leap_gravity: float = 300.0

var _origin_y: float
var _wait: float
var _leaping: bool = false


func _on_ready() -> void:
	immune_to_superballs = true
	_origin_y = global_position.y
	_wait = leap_interval * randf_range(0.3, 1.0)


func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY)
	collision_mask = 0   # passes through the water surface / tiles


func _alive_physics(delta: float) -> void:
	if not _leaping:
		_wait -= delta
		if _wait <= 0.0:
			_leaping = true
			velocity.y = -leap_speed
			_play_anim("jump")
		return
	velocity.y += leap_gravity * delta
	global_position.y += velocity.y * delta
	if sprite:
		sprite.flip_v = velocity.y > 0.0
	if velocity.y > 0.0 and global_position.y >= _origin_y:
		global_position.y = _origin_y
		_leaping = false
		_wait = leap_interval
		_play_anim("default")
