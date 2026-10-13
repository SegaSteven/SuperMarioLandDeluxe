extends Node
## Autoload "RunTimeLevel": when a level is beaten, remember it so the overworld can
## show it as complete and open paths that need it (see MapPath "required_level").

func _ready():
	GameManager.level_beaten.connect(beat_level)

func beat_level():
	OverworldMan.mark_beaten(OverworldMan.level_name)
	if GameManager.levels_beaten.has(OverworldMan.level_name):
		GameManager.levels_beaten[OverworldMan.level_name] = true
