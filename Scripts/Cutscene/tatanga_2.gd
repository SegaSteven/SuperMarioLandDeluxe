extends AnimatedSprite2D

@onready var path_follow_2d: PathFollow2D = $"../Path2D/PathFollow2D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var pathtween = get_tree().create_tween()
	pathtween.tween_property(path_follow_2d, "progress_ratio", 0, 0)
	pathtween.chain().tween_property(path_follow_2d, "progress_ratio", 1, 4).finished


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
