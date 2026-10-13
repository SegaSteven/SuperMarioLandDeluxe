extends Enemy

class_name HopperEnemy
## A ready-made HOPPING enemy. Attach this script to a new enemy scene and tune it in the
## Inspector - no code needed. Examples:
##   Small frog that hops forward:      hop_speed 90,  big_hop_speed 0,   face_player off
##   Fly-style (small, small, BIG):     hop_speed 90,  big_hop_speed 170, hops_before_big 2
##   Jumper that only hops in place:    air_speed 0
##
## Animations it looks for on the AnimatedSprite2D (any that are missing are skipped):
##   anim_ground while waiting, anim_air while in the air, "dead" when killed.

@export_group("Hopping")
@export var hop_speed: float = 100.0          ## upward speed of a normal hop
@export var big_hop_speed: float = 0.0        ## 0 = never does a big hop
@export var hops_before_big: int = 2          ## normal hops before each big hop
@export var wait_on_ground: float = 0.5       ## seconds it pauses between hops
@export var air_speed: float = 25.0           ## sideways speed while in the air (0 = straight up)
@export var face_player: bool = true          ## turn towards Mario before each hop

@export_group("Animations")
@export var anim_ground: StringName = &"default"
@export var anim_air: StringName = &"jump"

var _wait: float = 0.0
var _hops: int = 0


func _on_ready() -> void:
	_wait = wait_on_ground


func _alive_physics(delta: float) -> void:
	apply_gravity(delta)

	if is_on_floor():
		velocity.x = 0.0
		_play_anim(anim_ground)
		_wait -= delta
		if _wait <= 0.0:
			_hop()

	move_and_slide()

	# Bounce off walls while in the air
	if not is_on_floor() and is_on_wall():
		direction = -direction
		velocity.x = direction * air_speed
		_face(direction)


func _hop() -> void:
	if face_player:
		direction = direction_to_player()
	_face(direction)
	var big := big_hop_speed > 0.0 and _hops >= hops_before_big
	velocity.y = -(big_hop_speed if big else hop_speed)
	velocity.x = direction * air_speed
	_hops = 0 if big else _hops + 1
	_wait = wait_on_ground
	_play_anim(anim_air)
