extends Area2D

class_name Vine
## A climbable vine. Grows upwards from where it's placed until it reaches max_height.
## Mario climbs it with Up/Down (Climb state). Can also be placed in a level directly.
## If destination_scene is set, climbing to the top takes Mario there.

@export var max_height: float = 96.0
@export var grow_speed: float = 48.0
@export var start_grown: bool = false          ## tick for a vine placed in the level already grown
@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn: Vector2 = Vector2.ZERO
@export var color: Color = Color(0.25, 0.75, 0.3)

var height: float = 0.0
var _shape: RectangleShape2D


func _ready() -> void:
	add_to_group("vines")
	collision_layer = 0
	collision_mask = Layers.bit(Layers.PLAYER)
	_shape = RectangleShape2D.new()
	var cs := CollisionShape2D.new()
	cs.name = "CollisionShape2D"
	cs.shape = _shape
	add_child(cs)
	height = max_height if start_grown else 2.0
	_update_shape()
	body_entered.connect(func(b): if b is PlayerUpdated: b.touching_vine = self)
	body_exited.connect(func(b): if b is PlayerUpdated and b.touching_vine == self: b.touching_vine = null)


func _physics_process(delta: float) -> void:
	if height < max_height:
		height = minf(height + grow_speed * delta, max_height)
		_update_shape()


func _update_shape() -> void:
	# The vine grows UP from the node's position: its top is at y = -height
	_shape.size = Vector2(6, height)
	get_node("CollisionShape2D").position = Vector2(0, -height * 0.5)
	queue_redraw()


func top_y() -> float:
	return global_position.y - height


func is_fully_grown() -> bool:
	return height >= max_height


func has_destination() -> bool:
	return destination_scene != ""


func travel() -> void:
	GameManager.travel_to(destination_scene, destination_spawn, {"pattern": "squares", "speed": 4})


## Placeholder art: a green stem with leaves every 8 px. Replace with a sprite if you like.
func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -height), color, 1.5)
	var y := 4.0
	var left := true
	while y < height:
		var dir := -1.0 if left else 1.0
		draw_line(Vector2(0, -y), Vector2(3 * dir, -y - 2), color.lightened(0.2), 1.5)
		left = not left
		y += 8.0
