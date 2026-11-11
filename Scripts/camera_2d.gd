extends Camera2D

class_name PlayerCamera
## Follows Mario. While MainCamArea is moving the camera between areas (or holding it in a sky /
## cave area) it sets the camera's position instead - but never so far that Mario (the middle
## of him) would be off the screen.

func _process(_delta):
	var player := $"../Player" as Node2D
	var p: Vector2 = player.get_position()
	if has_meta("cam_area_x") or has_meta("cam_area_y"):
		if has_meta("cam_area_x"):
			p.x = get_meta("cam_area_x")
		if has_meta("cam_area_y"):
			p.y = get_meta("cam_area_y")
		if has_meta("cam_free"):               # a cutscene has the camera (Mario can be off screen)
			self.set_position(p); force_update_scroll(); return
		var half := get_viewport_rect().size * 0.5 / zoom
		var c := player.global_position
		var spr := player.get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
		if spr:
			c = spr.global_position + spr.offset          # the middle of his sprite
		p.x = clampf(p.x, c.x - half.x, c.x + half.x)
		p.y = clampf(p.y, c.y - half.y, c.y + half.y)
		self.set_position(p)
		force_update_scroll()           # show it this frame, not the next
		return
	self.set_position(p)
