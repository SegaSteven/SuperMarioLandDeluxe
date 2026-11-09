extends PlayerState
## Mario is inside something (a UFO, the SAM cannon...). He's invisible, doesn't move and
## nothing can touch him. Whatever put him here takes him out again, e.g.
##   player.state_machine.transition_to(&"Hidden")
##   ...
##   player.state_machine.transition_to(&"Air")


func _init() -> void:
	allows_contacts = false
	allows_damage = false
	allows_stomp = false
	allows_transform = false


func enter(_msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.visible = false


func physics_update(_delta: float) -> void:
	player.velocity = Vector2.ZERO


func exit() -> void:
	player.visible = true
