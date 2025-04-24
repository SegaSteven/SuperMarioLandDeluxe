extends Sprite2D


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var titletween = get_tree().create_tween()
	titletween.tween_property(self, "position", position + Vector2(0,44.7), 0.5)
	titletween.chain().tween_property(self, "position", position + Vector2(0,47), 0.1)
	titletween.chain().tween_property(self, "position", position + Vector2(0,44.7), 0.1)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
