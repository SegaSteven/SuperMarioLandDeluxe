extends CharacterBody2D

class_name PowerUpItem
## A power-up pickup for ANY entry in Scripts/Player/PowerUps.gd. Set Power Up Id in the
## Inspector ("fire", "bunny", "speed_shoes", "superball", "mushroom" or your own).
## Pops out of a block, then stays put, walks, or bounces. Mario collects it on touch.
##
## Locked power-ups: put the item in a ?-block's Spawned Scene as normal. Until it's unlocked
## the block gives a normal power-up instead (see questionblock.gd).

enum Movement { STAY, WALK, BOUNCE }

@export var power_up_id: String = "fire"
@export var movement: Movement = Movement.STAY
@export var speed: float = 24.0
@export var bounce_speed: float = 130.0
@export var gravity: float = 400.0
@export var emerge_distance: float = 5.0
@export var emerge_time: float = 0.3
@export var placed_in_level: bool = false     ## tick when it sits in the level instead of coming out of a block

var direction: int = 1
var _emerged: bool = false
var _taken: bool = false


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BONUS)
	collision_mask = 0
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite and sprite.sprite_frames and sprite.sprite_frames.get_animation_names().size() > 0:
		sprite.play()
	if placed_in_level:
		_finish_emerging()
		return
	var sfx := get_node_or_null("Blockhititem") as AudioStreamPlayer
	if sfx:
		sfx.play()
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - emerge_distance, emerge_time)
	tween.tween_callback(_finish_emerging)


func _finish_emerging() -> void:
	_emerged = true
	if movement != Movement.STAY:
		collision_mask = Layers.WORLD_MASK


func _physics_process(delta: float) -> void:
	if not _emerged or movement == Movement.STAY:
		return
	velocity.y += gravity * delta
	velocity.x = direction * speed
	move_and_slide()
	if movement == Movement.BOUNCE and is_on_floor():
		velocity.y = -bounce_speed
	if is_on_wall():
		direction = 1 if get_wall_normal().x > 0.0 else -1
	if global_position.y > 600.0:
		queue_free()


## Mario asks this before collecting (no double pickups, not mid-emerge for walking items).
func can_collect() -> bool:
	return not _taken


func collected() -> void:
	_taken = true
	queue_free()
