extends AnimatableBody2D

class_name LiftPlatform
## The lift a hidden block lets out (1-3). It rises steadily, carrying Mario up so he can step
## off onto the top of the level. Once it has gone out of the top of the main camera area
## (the level's MainCamArea, or the camera's top limit) it vanishes - if Mario is still on it
## then, he drops back down.

@onready var blockhititem: AudioStreamPlayer = $Blockhititem

## Pixels per second (negative = up).
@export var speed: float = -10.0
## Extra pixels past the top of the camera area before it vanishes.
@export var vanish_margin: float = 8.0


func _ready() -> void:
	blockhititem.play()
	sync_to_physics = true                          # Mario rides it like a proper moving platform


func _physics_process(delta: float) -> void:
	position += Vector2(0, speed) * delta
	if global_position.y < _area_top() - vanish_margin:
		queue_free()


## The top of the main camera area.
func _area_top() -> float:
	var scene := get_tree().current_scene
	if scene:
		var mains := scene.find_children("*", "MainCamArea", true, false)
		if mains.size() > 0:
			return (mains[0] as MainCamArea).area_rect().position.y
	var cam := get_viewport().get_camera_2d()
	return float(cam.limit_top) if cam else -100000.0
