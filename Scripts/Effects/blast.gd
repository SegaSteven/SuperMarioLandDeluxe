extends Node2D

class_name Blast
## The little explosion an enemy turns into when the boss switch blows everything up.
## Swap the frames in the AnimatedSprite2D (placeholders: Assets/Sprites/Blast/blast_1..4.png,
## 8 x 8). The "default" animation plays once, then it's removed.


func _ready() -> void:
	var spr := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if spr and spr.sprite_frames and spr.sprite_frames.has_animation("default"):
		spr.play("default")
		spr.animation_finished.connect(queue_free)
	else:
		get_tree().create_timer(0.3).timeout.connect(queue_free)
