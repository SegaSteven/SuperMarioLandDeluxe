extends Area2D

class_name ShootingFlower

@onready var animated_sprite_2d = $AnimatedSprite2D

func _ready():
	animated_sprite_2d.play("flower")
	$Blockhititem.play()
	var spawn_tween = get_tree().create_tween()
	spawn_tween.tween_property(self, "position", position + Vector2(0, -4), .3)
	spawn_tween.chain().tween_property(self, "postiion", position + Vector2(0, -8), 0.2)

func free_change_scene():
		queue_free()
