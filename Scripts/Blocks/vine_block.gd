extends QuestionBlock

class_name VineBlock
## Like the NES Super Mario Bros vine block: bump it and a vine grows up out of it.
## Mario holds Up on the vine to climb it (the Climb state).
##
## Where the vine goes:
##   - leave Destination Scene empty and the vine is just a ladder up to wherever you like in
##     this level (e.g. a ledge with a SECRET exit on it), or
##   - fill in Destination Scene + Spawn and climbing to the top takes Mario there
##     (a bonus sky area that ends at a secret exit, like the NES game).

@export_group("Vine")
@export var vine_height: float = 96.0                 ## pixels the vine grows
@export var grow_speed: float = 48.0                  ## pixels per second
@export_file("*.tscn") var destination_scene: String = ""
@export var destination_spawn: Vector2 = Vector2.ZERO

const VINE_SCENE = preload("res://Scenes/Blocks/vine.tscn")


func _ready() -> void:
	super._ready()
	if animated_sprite_2d:
		animated_sprite_2d.modulate = Color(0.6, 1.0, 0.6)   # placeholder: a green-tinted ? block


func spawn_item() -> void:
	var vine = VINE_SCENE.instantiate()
	vine.max_height = vine_height
	vine.grow_speed = grow_speed
	vine.destination_scene = destination_scene
	vine.destination_spawn = destination_spawn
	get_parent().add_child(vine)
	vine.global_position = global_position + Vector2(0, -4)
	var sfx := get_node_or_null("Blockhititem") as AudioStreamPlayer
	if sfx:
		sfx.play()
