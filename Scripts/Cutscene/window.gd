extends AnimatedSprite2D

signal smash

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(10.7).timeout
	play("Broken")
	smash.emit()


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
