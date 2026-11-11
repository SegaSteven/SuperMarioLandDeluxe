@tool
extends CamArea

class_name CaveCamArea
## A secret area BELOW the main camera area (green outline). Put it under the bottom of the
## level's MainCamArea, overlapping the red box's bottom edge by about 16 pixels. When Mario, going
## down, gets within 3 pixels (Switch Margin) of the main camera's bottom edge while touching this box (e.g. falling down a
## hole), the camera glides down into it (Mario at the top of the screen) instead of him dying.
## The death line moves to the bottom of this box: falling out of the bottom of it loses a life.
## Make it at least one screen (256 x 144) in size.

## Falling out of the bottom of this box loses a life (untick if something else catches him).
@export var death_at_bottom: bool = true


func edge_color() -> Color:
	return Color(0.15, 0.85, 0.25)
