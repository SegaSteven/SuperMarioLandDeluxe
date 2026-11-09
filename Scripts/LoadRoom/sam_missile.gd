extends Node2D

class_name SamMissile
## The missile the SAM cannon fires. Placeholder drawing unless a texture is given
## (draw it pointing RIGHT).

var texture: Texture2D
var _flame: float = 0.0


func fly_to(target: Vector2, speed: float) -> void:
	rotation = (target - global_position).angle()
	var time := maxf(global_position.distance_to(target) / speed, 0.15)
	var tw := create_tween()
	tw.tween_property(self, "global_position", target, time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	await tw.finished
	queue_free()


func _process(delta: float) -> void:
	_flame += delta
	# smoke puffs left behind
	if int(_flame * 30.0) % 3 == 0:
		var puff := SamExplosion.new()
		puff.smoke = true
		get_parent().add_child(puff)
		puff.global_position = global_position - Vector2.RIGHT.rotated(rotation) * 5.0
	queue_redraw()


func _draw() -> void:
	if texture:
		draw_texture(texture, -texture.get_size() * 0.5)
		return
	draw_rect(Rect2(-4, -1.5, 8, 3), Color(0.85, 0.85, 0.9))
	draw_colored_polygon(PackedVector2Array([Vector2(4, -1.5), Vector2(7, 0), Vector2(4, 1.5)]), Color(0.9, 0.2, 0.2))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -1.5), Vector2(-6, -3), Vector2(-3, -1.5)]), Color(0.6, 0.6, 0.65))
	draw_colored_polygon(PackedVector2Array([Vector2(-4, 1.5), Vector2(-6, 3), Vector2(-3, 1.5)]), Color(0.6, 0.6, 0.65))
	var f := 2.0 + (int(_flame * 20.0) % 2) * 1.5
	draw_colored_polygon(PackedVector2Array([Vector2(-4, -1), Vector2(-4 - f, 0), Vector2(-4, 1)]), Color(1, 0.7, 0.1))
