extends Node2D


class_name LoadRoom

## The load room (comes after the title screen). Mario walks about, climbs a ladder into one
## of the 3 UFOs to play that save file, or uses the SAM cannon on the right to delete one.
##   picked a NEW (empty) file   -> New File Scene (Daisy's letter), then the map
##   picked a file with progress -> straight back to the map he was last on

@export_file("*.tscn") var new_file_scene: String = "res://Scenes/Letter_Screen.tscn"
@export_file("*.tscn") var default_map_scene: String = "res://Scenes/WorldScenes/world_map.tscn"
@export var start_position: Vector2 = Vector2(20, 112)
@export var transition: Dictionary = {"pattern": "fade", "speed": 3}
@onready var animation_player: AnimationPlayer = $AnimationPlayer

@onready var player: PlayerUpdated = $Player


func _ready() -> void:
	GameManager.reset_game_state()
	player.set_mode(PlayerUpdated.PlayerMode.SMALL)
	player.animated_sprite_2d.play("%s_run")
	player.global_position = start_position
	player.input_pickable = false
	

	
	for ufo in get_tree().get_nodes_in_group("save_ufos"):
		ufo.boarded.connect(_start_file)
		ufo.refresh()


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
