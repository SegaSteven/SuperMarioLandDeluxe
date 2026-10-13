extends CharacterBody2D

class_name Shroom
## Super Mushroom. Pops out of a block, then walks right. Mario picks it up (see Player_Updated.gd).

@export var horizontal_speed: float = 20.0
@export var gravity: float = 400.0
@export var emerge_distance: float = 5.0
@export var emerge_time: float = 0.3

var direction: int = 1
var _emerged: bool = false


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BONUS)
	collision_mask = 0     # no collisions while popping out of the block
	var sfx := get_node_or_null("Blockhititem") as AudioStreamPlayer
	if sfx:
		sfx.play()
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - emerge_distance, emerge_time)
	tween.tween_callback(_finish_emerging)


func _finish_emerging() -> void:
	_emerged = true
	collision_mask = Layers.WORLD_MASK


func _physics_process(delta: float) -> void:
	if not _emerged:
		return
	if not is_on_floor():
		velocity.y += gravity * delta
	velocity.x = direction * horizontal_speed
	move_and_slide()
	if is_on_wall():
		direction = 1 if get_wall_normal().x > 0.0 else -1
	if global_position.y > 600.0:
		queue_free()
