extends Enemy

class_name Orbiter
## Something that circles around a point: Roto Disc, Chikako (World 4 sparks), or Tamao
## (the balls that guard Dragonzamasu). Can't be stomped; by default can't be destroyed either.
##
## orbit_center: leave empty to circle where it was placed, or point it at a node (e.g. the
## Dragonzamasu boss) to circle around that.

@export var orbit_center: NodePath
@export var radius: float = 24.0
@export var degrees_per_second: float = 120.0
@export var start_angle: float = 0.0
@export var destructible: bool = false

var _angle: float
var _home: Vector2


func _on_ready() -> void:
	can_be_stomped = false
	immune_to_projectiles = not destructible
	always_active = true
	_angle = deg_to_rad(start_angle)
	_home = global_position


func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY)
	collision_mask = 0


func _alive_physics(delta: float) -> void:
	var centre := _home
	if not orbit_center.is_empty():
		var c := get_node_or_null(orbit_center) as Node2D
		if c == null or (c is Enemy and c.is_dead):
			die_from_hit(0.0)
			return
		centre = c.global_position
	_angle += deg_to_rad(degrees_per_second) * delta
	global_position = centre + Vector2(radius, 0).rotated(_angle)
