@tool
extends ReferenceRect

class_name CamArea
## Base for the camera areas (MainCamArea, SkyCamArea, CaveCamArea). Each one is a box you place
## and resize in the editor like any other Control (drag its edges), drawn only as a coloured
## OUTLINE so it doesn't tint the level while you build it. The boxes are hidden in the game.
##   MainCamArea (red)   - the normal camera area of the level (one per level, it runs the others)
##   SkyCamArea  (blue)  - a secret area above it
##   CaveCamArea (green) - a secret area below it
## See main_cam_area.gd for how the camera moves between them.

@export var edge_width: float = 2.0:
	set(v):
		edge_width = v
		border_width = v


func _init() -> void:
	editor_only = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_width = edge_width
	border_color = edge_color()


func _ready() -> void:
	editor_only = true
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	border_width = edge_width
	border_color = edge_color()
	if not Engine.is_editor_hint():
		add_to_group("cam_areas")


## The outline colour (each kind sets its own).
func edge_color() -> Color:
	return Color(1, 1, 1)


## The box in the level.
func area_rect() -> Rect2:
	return get_global_rect()
