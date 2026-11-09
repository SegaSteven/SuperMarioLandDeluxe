extends Node2D

class_name SamExplosion
## Placeholder explosion (or a smoke puff when smoke = true). Frees itself when done.

var smoke: bool = false
var _t: float = 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= (0.35 if smoke else 0.7):
		queue_free()
	queue_redraw()


func _draw() -> void:
	if smoke:
		draw_circle(Vector2.ZERO, 1.0 + _t * 6.0, Color(0.8, 0.8, 0.8, 0.6 * (1.0 - _t / 0.35)))
		return
	var k := _t / 0.7
	var flash := int(_t * 20.0) % 2 == 0
	draw_circle(Vector2.ZERO, 4.0 + k * 16.0, Color(1, 0.55, 0.1, 1.0 - k))
	draw_circle(Vector2.ZERO, 2.0 + k * 10.0, Color(1, 0.95, 0.4, 1.0 - k) if flash else Color(1, 1, 1, 1.0 - k))
	for i in 6:
		var a := i * TAU / 6.0 + k
		draw_rect(Rect2(Vector2(cos(a), sin(a)) * (6.0 + k * 22.0) - Vector2(1, 1), Vector2(2, 2)), Color(0.9, 0.9, 0.9, 1.0 - k))
