extends Label
## The score that pops up when Mario gets points (killing an enemy any way - stomp, superball,
## star, kick - plus coins, star coins...). It floats straight up Rise pixels, then vanishes.

## Pixels it floats up before vanishing.
@export var rise: float = 32.0
## Seconds it takes to float up.
@export var rise_time: float = 0.8

@onready var score : int
@onready var points_label: Label = $"."

func _ready():
	points_label.text = str(score)
	var label_tween = create_tween()
	label_tween.tween_property(self, "position", position + Vector2(0, -rise), rise_time)
	label_tween.tween_callback(queue_free)
