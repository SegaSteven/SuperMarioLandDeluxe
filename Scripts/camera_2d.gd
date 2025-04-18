extends Camera2D

class_name PlayerCamera

#func _ready():
	#self.set_position($"../Player".get_position())
	
func _process(delta):
	self.set_position($"../Player".get_position())
