extends Label

@onready var label: Label = $"."

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	await get_tree().create_timer(3).timeout
	label.text = str("M")
	await get_tree().create_timer(0.2).timeout
	label.text = str("MA")
	await get_tree().create_timer(0.2).timeout
	label.text = str("MAR")
	await get_tree().create_timer(0.2).timeout
	label.text = str("MARI")
	await get_tree().create_timer(0.2).timeout
	label.text = str("MARIO")
	await get_tree().create_timer(0.2).timeout
	label.text = str("MARIO!")
	await get_tree().create_timer(4).timeout
	label.text = str("")
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
