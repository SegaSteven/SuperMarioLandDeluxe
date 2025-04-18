extends StaticBody2D

class_name FallingBlock

@onready var player: Player = $"../Player"
@onready var collision_shape_2d: CollisionShape2D = $Sprite2D/Area2D/CollisionShape2D
@onready var area_2d: Area2D = $Sprite2D/Area2D

func _on_area_2d_body_entered(body: Player) -> void:
	var plattween = get_tree().create_tween()
	plattween.tween_property(self, "position", position + Vector2(0,0), .3)
	plattween.chain().tween_property(self, "position", position + Vector2(0, 200), 3)
	await get_tree().create_timer(0.3).timeout
	set_collision_layer_value(5, false)
	set_collision_mask_value(1, false)
	area_2d.set_collision_layer_value(5, false)
	area_2d.set_collision_mask_value(1, false)
