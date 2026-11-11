@tool
extends CamArea

class_name DaisyCamArea
## The fake Daisy room (pink outline). Draw it around the room behind the door, at least one
## screen (256 x 144) in size, and drag it into the FakeDaisy node's Daisy Cam Area.
## Nothing happens when Mario walks into it - the FakeDaisy cutscene pans the camera over to it
## when its timing says so (Pan Delay / Pan Time), and the camera then stays in this box.
## While the cutscene has the camera, the MainCamArea's switching and death line are switched off.


func edge_color() -> Color:
	return Color(1.0, 0.4, 0.8)
