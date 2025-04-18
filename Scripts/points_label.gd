extends Label

@onready var score : int
@onready var points_label: Label = $"."

func _ready():
	points_label.text = str(score)
	var label_tween = get_tree().create_tween()
	label_tween.tween_property(self, "position", position + Vector2(0, -5), .4)
	label_tween.tween_callback(queue_free)
