extends Area2D

class_name Door

signal player_entered_door(door: Door, transition_type: String)

@export_enum("north", "east", "south", "west") var entry_direciton
@export_enum("fade_to_black","wipe_to_right","zelda") var transition_type:String
@export var push_distance:int = 16
@export var path_to_new_scene:String
@export var entry_door_name:String

func _on_body_entered(body: Node2D):
	if body is Player:
		return
	player_entered_door.emit(self)
	if transition_type == "zelda":
		SceneSwitcher.load_level_zelda(path_to_new_scene)
	else:
		SceneSwitcher.load_new_scene(path_to_new_scene,transition_type)
	queue_free()
#// UTILITY FUNCTIONS //

# returns the starting location of the player based on this door's location and
# the entry_direction (the Vector towards the room)
func get_player_entry_vector() -> Vector2:
	var vector:Vector2 = Vector2.LEFT
	match entry_direciton:
		0:
			vector = Vector2.UP
		1:
			vector = Vector2.RIGHT
		2:
			vector = Vector2.DOWN
	return (vector * push_distance) + self.position
	
func get_move_dir() -> Vector2:
	var dir:Vector2 = Vector2.RIGHT
	match entry_direciton:
		0:
			dir = Vector2.DOWN
		1:
			dir = Vector2.LEFT
		2:
			dir = Vector2.UP
	return dir
