extends Area2D

class_name FallingSlab
## A ceiling slab (1-3) that drops when Mario walks under it. Once it starts it doesn't stop:
## it shakes for Drop Delay seconds, then falls all the way down and off the screen. If it
## lands on Mario he gets hurt (small Mario loses a life) - or dies outright with Kill Instantly.
## The RayCast2D (pointing down) is how far below it Mario has to be to set it off.

signal slab_hit

## Seconds it shakes before it drops (Mario's chance to get out of the way).
@export var drop_delay: float = 1.0
## Shake while waiting to drop.
@export var shake: bool = true
@export var fall_gravity: float = 100.0
@export var max_fall_speed: float = 43.5
## Landing on Mario kills him whatever his size (otherwise it hurts him like an enemy does).
@export var kill_instantly: bool = false

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D
@onready var sprite: Node2D = get_node_or_null("Sprite2D")

enum SlabState { WAITING, SHAKING, FALLING }
var state: SlabState = SlabState.WAITING
var _timer: float = 0.0
var _speed: float = 0.0
var _hit_done: bool = false


func _ready() -> void:
	monitoring = true
	collision_mask = Layers.bit(Layers.PLAYER)
	if ray_cast_2d:
		ray_cast_2d.collision_mask = Layers.bit(Layers.PLAYER)
		ray_cast_2d.collide_with_areas = true


func _physics_process(delta: float) -> void:
	match state:
		SlabState.WAITING:
			if ray_cast_2d and ray_cast_2d.is_colliding():
				start()
		SlabState.SHAKING:
			_timer -= delta
			if sprite and shake:
				sprite.position.x = 1.0 if int(_timer * 30.0) % 2 == 0 else -1.0
			if _timer <= 0.0:
				if sprite:
					sprite.position.x = 0.0
				state = SlabState.FALLING
		SlabState.FALLING:
			_speed = minf(_speed + fall_gravity * delta, max_fall_speed)
			position.y += _speed * delta
			_check_hit()
			var cam := get_viewport().get_camera_2d()
			var bottom := (cam.get_screen_center_position().y + 90.0) if cam else 400.0
			if global_position.y > bottom + 16.0:
				queue_free()


## Sets the slab off (also callable from a level script).
func start() -> void:
	if state != SlabState.WAITING:
		return
	state = SlabState.SHAKING
	_timer = drop_delay


func _check_hit() -> void:
	if _hit_done:
		return
	for a in get_overlapping_areas():
		_try_hit(a.get_parent())
	for b in get_overlapping_bodies():
		_try_hit(b)


func _try_hit(n: Node) -> void:
	var m := n as PlayerUpdated
	if m == null or m.is_dead or _hit_done:
		return
	_hit_done = true
	slab_hit.emit()
	if kill_instantly:
		m.die(true)
	else:
		m.hurt(self)


func _on_area_entered(_area: Area2D) -> void:
	pass   # hits are checked while it falls (see _check_hit)
