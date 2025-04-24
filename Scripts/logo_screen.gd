extends Node

@onready var logo_tween = create_tween()
@export var next_scene = "res://Scenes/title_screen.tscn"

func _ready():
	
	logo_tween.tween_property(self, "position", Vector2(-132, -5), .0)
	logo_tween.chain().tween_property(self, "position", Vector2(-132, 72), 3)
	logo_tween.chain().finished
	await get_tree().create_timer(3).timeout
	$"../LogoTing".play()
	

	await get_tree().create_timer(1).timeout
	SceneManager.change_scene(next_scene, {"pattern": "circle", "speed": 4})
