@tool
extends CamArea

class_name SkyCamArea
## A secret area ABOVE the main camera area (blue outline). Put it over the top of the level's
## MainCamArea, overlapping the red box's top edge by about 16 pixels. When Mario, going up,
## gets within 3 pixels (Switch Margin) of the main camera's top edge while touching this box, the camera glides up into it
## (Mario at the bottom of the screen). Falling back within 3 pixels of this box's bottom edge glides back.
## There's no death line here: if Mario falls, he drops back down into the main area.
## Make it at least one screen (256 x 144) in size.


func edge_color() -> Color:
	return Color(0.2, 0.35, 1.0)
