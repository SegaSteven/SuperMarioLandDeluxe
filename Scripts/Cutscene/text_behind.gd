extends ColorRect


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	visible = false
	await get_tree().create_timer(4).timeout
	visible = true
	await get_tree().create_timer(0.2).timeout
	size.x = 16
	await get_tree().create_timer(0.2).timeout
	size.x = 24
	await get_tree().create_timer(0.4).timeout
	size.x = 40
	await get_tree().create_timer(0.2).timeout
	size.x = 48
	await get_tree().create_timer(0.2).timeout
	size.x = 56
	await get_tree().create_timer(0.2).timeout
	size.x = 64
	await get_tree().create_timer(0.2).timeout
	size.x = 72
	await get_tree().create_timer(0.5).timeout
	visible = false

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
