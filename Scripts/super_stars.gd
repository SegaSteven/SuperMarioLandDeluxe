extends CharacterBody2D

class_name SuperStar
## Invincibility star. Pops out of a block, then bounces along the ground.

signal got_bonus(star)

@export var horizontal_speed: float = 30.0
@export var bounce_speed: float = 130.0
@export var gravity: float = 400.0
@export var emerge_distance: float = 5.0
@export var emerge_time: float = 0.3

var direction: int = 1
var _emerged: bool = false


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BONUS)
	collision_mask = 0
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
	velocity.y += gravity * delta
	velocity.x = direction * horizontal_speed
	move_and_slide()
	if is_on_floor():
		velocity.y = -bounce_speed
	elif is_on_ceiling():
		velocity.y = 0.0
	if is_on_wall():
		direction = 1 if get_wall_normal().x > 0.0 else -1
	if global_position.y > 600.0:
		queue_free()
