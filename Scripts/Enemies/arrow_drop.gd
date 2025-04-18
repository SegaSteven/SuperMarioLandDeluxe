extends Enemy

class_name ArrowDrop

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	vertical_speed = 50


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.y += delta * vertical_speed
