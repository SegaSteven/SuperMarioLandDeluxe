extends Node2D

class_name LoadRoom

## The load room (comes after the title screen). It opens with the boat intro (Intro node), then
## Mario walks about, taps Up at a ladder to climb into one of the 3 UFOs and play that save
## file, or uses the SAM cannon on the right to delete one.
##   picked a NEW (empty) file   -> New File Scene (Daisy's letter), then the map
##   picked a file with progress -> straight back to the map he was last on

@export_file("*.tscn") var new_file_scene: String = "res://Scenes/Letter_Screen.tscn"
@export_file("*.tscn") var default_map_scene: String = "res://Scenes/WorldScenes/world_map.tscn"
## Where Mario stands when the room starts (the boat intro jumps him here).
@export var start_position: Vector2 = Vector2(24, 120)
## The wipe used when leaving the room (to the letter or the map). "squares" = your squares wipe.
@export var transition: Dictionary = {"pattern": "squares", "speed": 4}

@onready var player: PlayerUpdated = $Player
## The boat intro (Intro node). Untick its Play Intro to start straight on the UFO screen.
@onready var intro: LoadRoomIntro = get_node_or_null("Intro")


func _ready() -> void:
	GameManager.reset_game_state()
	player.set_mode(PlayerUpdated.PlayerMode.SMALL)
	player.global_position = start_position
	for ufo in get_tree().get_nodes_in_group("save_ufos"):
		ufo.boarded.connect(_start_file)
		ufo.refresh()
	if intro and intro.play_intro:
		intro.play(player, start_position)


func _start_file(slot: int) -> void:
	var is_new := OverworldMan.select_slot(slot)
	GameManager.reset_game_state()
	OverworldMan.spawn_point = Vector2.ZERO
	var next := new_file_scene
	if not is_new:
		next = OverworldMan.last_map_scene
		if next == "" or not ResourceLoader.exists(next):
			next = default_map_scene
	SceneManager.change_scene(next, transition)
