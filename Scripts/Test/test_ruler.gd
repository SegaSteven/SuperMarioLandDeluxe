@tool
extends Node2D
## Test level helper: tick marks along the ground every 16 px (long ones every 64) and a height
## ruler every 8 px, so you can measure Mario's runs and jumps.

@export var ground_y: float = 128.0
@export var length: float = 4000.0
@export var ruler_every: float = 512.0     ## a height ruler every this many pixels
@export var ruler_height: float = 96.0

func _draw() -> void:
	var font := ThemeDB.fallback_font
	var x := 0.0
	while x <= length:
		var big := int(x) % 64 == 0
		draw_line(Vector2(x, ground_y), Vector2(x, ground_y + (6.0 if big else 3.0)), Color(0, 0, 0, 0.7), 1.0)
		x += 16.0
	var rx := 96.0
	while rx <= length:
		draw_line(Vector2(rx, ground_y), Vector2(rx, ground_y - ruler_height), Color(1, 1, 1, 0.8), 1.0)
		var h := 8.0
		while h <= ruler_height:
			var w := 6.0 if int(h) % 16 == 0 else 3.0
			draw_line(Vector2(rx - w, ground_y - h), Vector2(rx, ground_y - h), Color(1, 1, 1, 0.9), 1.0)
			if int(h) % 16 == 0:
				draw_string(font, Vector2(rx + 2, ground_y - h + 3), str(int(h)), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, Color(1, 1, 1))
			h += 8.0
		rx += ruler_every
