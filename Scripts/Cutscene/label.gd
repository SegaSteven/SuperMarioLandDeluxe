extends Label

@onready var label: Label = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(4).timeout
	label.text = str("T")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TO")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO ")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO L")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO LA")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO LAT")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO LATE")
	await get_tree().create_timer(0.2).timeout
	label.text = str("TOO LATE!")
	await get_tree().create_timer(0.5).timeout
	label.text = str("")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
