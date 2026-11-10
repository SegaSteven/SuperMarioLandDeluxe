extends Node2D

class_name LoadRoomDock
## The dock the speedboat pulls up to in the load room intro. It's only scenery: it sits BEHIND
## the boat (it's above the Boat node in the scene tree) and Mario doesn't stand on it.
## YOUR ART: add a Sprite2D child called "Body" and the placeholder drawing switches off.
## Its position is the right-hand end of the dock at deck height.

@export var length: float = 72.0
@export var plank_color: Color = Color(0.62, 0.42, 0.22)
@export var post_color: Color = Color(0.42, 0.27, 0.13)


func _ready() -> void:
	queue_redraw()


func _draw() -> void:
	if get_node_or_null("Body") != null:
		return
	# posts going down into the water
	var x := -4.0
	while x > -length:
		draw_rect(Rect2(x - 2, -1, 3, 18), post_color)
		x -= 16.0
	# deck boards
	draw_rect(Rect2(-length, -4, length, 4), plank_color)
	var px := -length
	while px < 0.0:
		draw_line(Vector2(px, -4), Vector2(px, 0), plank_color.darkened(0.3), 1.0)
		px += 6.0
	draw_line(Vector2(-length, -4), Vector2(0, -4), plank_color.lightened(0.2), 1.0)
