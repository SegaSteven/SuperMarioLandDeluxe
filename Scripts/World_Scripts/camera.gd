extends Camera2D


@onready var overworld_player: OverworldPlayer = %OverworldPlayer


func _process(delta):
	self.global_position = overworld_player.global_position
