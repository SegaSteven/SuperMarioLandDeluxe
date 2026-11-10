extends PlayerState
## Mario is being moved by a cutscene (e.g. the load room boat intro). He's visible but the
## player can't control him, nothing can hurt him, and gravity is off - the cutscene sets his
## position and animation itself. Put him back with machine.transition_to(&"Ground").
##   player.state_machine.transition_to(&"Scripted")


func _init() -> void:
	allows_contacts = false
	allows_damage = false
	allows_stomp = false
	allows_transform = false


func enter(_msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.visible = true


func physics_update(_delta: float) -> void:
	player.velocity = Vector2.ZERO
