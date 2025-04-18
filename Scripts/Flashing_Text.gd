extends Label

@export var speed : int = 5
@export var fade : bool = false

var time = 0
var sintime = 0
var showing = true

func flashMyText():
	if !fade:
		if sintime > 0:
			showing = true
		else:
			showing = false
			
	else:
		showing = true
		modulate.a = sintime
	visible = showing
		
func _physics_process(delta):
	await get_tree().create_timer(3).timeout
	flashMyText()
	time += delta
	sintime = sin(time*speed)
	flashMyText()
