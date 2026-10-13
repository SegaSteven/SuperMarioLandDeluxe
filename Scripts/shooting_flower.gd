extends CharacterBody2D

class_name ShootingFlower
## Flower power-up. Pops out of a block and stays put.

@export var emerge_distance: float = 5.0
@export var emerge_time: float = 0.3


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BONUS)
	collision_mask = 0
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.play("flower")
	var sfx := get_node_or_null("Blockhititem") as AudioStreamPlayer
	if sfx:
		sfx.play()
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - emerge_distance, emerge_time)


func free_change_scene() -> void:
	queue_free()
