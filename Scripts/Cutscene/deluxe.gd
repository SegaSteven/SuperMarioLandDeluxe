extends AnimatedSprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	self.modulate.a = 0.0
	await get_tree().create_timer(1).timeout
	var deluxetween = get_tree().create_tween()
	deluxetween.tween_property(self, "modulate:a", 0.0, 0.0)
	deluxetween.chain().tween_property(self, "modulate:a", 1.0, 0.2)
	play("Shine")
	await get_tree().create_timer(0.5).timeout
	play("default")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
