extends PlayerState
## Sliding into a pipe. Enter with:
##   machine.transition_to("Pipe", {"offset": Vector2(0, 16), "pipe": the_pipe, "done": some_signal})
## When the slide finishes:
##   - if the pipe has a Destination Scene set, Mario travels there (GameManager.travel_to)
##   - otherwise `done` is emitted and the level script decides (the old way)

@export var slide_time: float = 1.0


func _init() -> void:
	allows_contacts = false
	allows_damage = false


func enter(msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	GameManager.player_mode = player.player_mode
	var offset: Vector2 = msg.get("offset", Vector2(0, 16))
	var pipe = msg.get("pipe")
	var done = msg.get("done")
	var tween := player.create_tween()
	tween.tween_property(player, "position", player.position + offset, slide_time)
	tween.tween_callback(func():
		if pipe != null and is_instance_valid(pipe) and pipe.has_method("has_destination") and pipe.has_destination():
			pipe.travel()
		elif done is Signal:
			done.emit())
