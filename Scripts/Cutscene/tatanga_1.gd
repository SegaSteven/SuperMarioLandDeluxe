extends AnimatedSprite2D

@onready var path_follow_2d: PathFollow2D = $"../Path2D/PathFollow2D"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	flip_h = false
	await get_tree().create_timer(2.2).timeout
	var tween = get_tree().create_tween()
	tween.tween_property(path_follow_2d, "h_offset", (130), .3)
	tween.chain().tween_property(path_follow_2d, "h_offset", (4), 1).finished
	await tween.finished
	await get_tree().create_timer(3.5).timeout
	var fliptween = get_tree().create_tween()
	var pathtween = get_tree().create_tween()
	pathtween.tween_property(path_follow_2d, "progress_ratio", 0, 0)
	pathtween.chain().tween_property(path_follow_2d, "progress_ratio", 0.2286, 1).finished
	fliptween.tween_property(self, "flip_h", true, 1.3)
	pathtween.chain().tween_property(path_follow_2d, "progress_ratio", 0.5, 1).finished
	fliptween.chain().tween_property(self, "flip_h", false, 1.3)
	pathtween.chain().tween_property(path_follow_2d, "progress_ratio", 0.7715, 1).finished
	fliptween.chain().tween_property(self, "flip_h", true, 1.3)
	pathtween.chain().tween_property(path_follow_2d, "progress_ratio", 1, 1)
	await get_tree().create_timer(3.8).timeout
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
