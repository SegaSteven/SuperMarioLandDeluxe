extends Vine

class_name Ladder
## A ladder Mario climbs with Up/Down (uses the same Climb state as vines).
## Put it with its BOTTOM on the floor; it goes up Max Height pixels.
## Ufo: drag a SaveUfo in. Climbing off the top of the ladder puts Mario in that UFO.

@export var ufo: NodePath
@export var rail_color: Color = Color(0.75, 0.5, 0.25)
@export var rung_spacing: float = 6.0
@onready var sprite_2d: Sprite2D = $Sprite2D


func _init() -> void:
	start_grown = true


## Called by the Climb state when Mario reaches the top. true = handled.
func reached_top(player: PlayerUpdated) -> bool:
	var target := get_node_or_null(ufo) as SaveUfo
	if target == null or not target.can_board():
		return false
	target.board(player)
	return true


## Placeholder art: two rails and rungs. Delete this function and add a Sprite2D for real art.
func _draw() -> void:
	sprite_2d.region_enabled = true
	# Set region_rect to a Rect2(x, y, width, height)
	sprite_2d.region_rect = Rect2(32, 0, 16, 16)
	
	draw_line(Vector2(-4, 0), Vector2(-4, -height), rail_color, 1.0)
	draw_line(Vector2(4, 0), Vector2(4, -height), rail_color, 1.0)
	var y := 3.0
	while y < height:
		draw_line(Vector2(-4, -y), Vector2(4, -y), rail_color.lightened(0.2), 1.0)
		y += rung_spacing
