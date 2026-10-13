extends Label
## Blinking / pulsing text (e.g. "PRESS START").
## The old version started a new 3 second timer every frame; now it just counts time.

@export var speed: float = 5.0
@export var fade: bool = false          ## true = pulse transparency, false = blink on/off
@export var start_delay: float = 3.0    ## wait this long before it starts flashing

var _time: float = 0.0


func _process(delta: float) -> void:
	_time += delta
	if _time < start_delay:
		return
	var wave := sin((_time - start_delay) * speed)
	if fade:
		visible = true
		modulate.a = (wave + 1.0) * 0.5
	else:
		visible = wave > 0.0
