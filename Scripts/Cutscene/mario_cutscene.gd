extends AnimatedSprite2D

class_name MarioCutscene

enum PlayerMode {
	SMALL,
	BIG
}

var player_mode = PlayerMode.BIG

var mario_position = self.global_position

func _ready():
	player_mode = GameManager.player_mode
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	
	# Animation Start
	play("%s_run" % animation_prefix)
	var mariotween = get_tree().create_tween()
	mariotween.tween_property(self, "position", position + Vector2(0, 0), .3)
	mariotween.chain().tween_property(self, "position", position + Vector2(200, 0), 2.6).finished
	await mariotween.finished
	play("%s_idle" % animation_prefix)
	await get_tree().create_timer(4).timeout
	var fliptween = get_tree().create_tween()
	fliptween.tween_property(self, "flip_h", true, 0)
	fliptween.chain().tween_property(self, "flip_h", false, 2.5)
	fliptween.chain().tween_property(self, "flip_h", true, 0.3)
	fliptween.chain().tween_property(self, "flip_h", false, 0.5)

func _process(delta: float) -> void:
	pass


func _on_window_smash():
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	play("%s_run" % animation_prefix)
	var mariotween = get_tree().create_tween()
	mariotween.tween_property(self, "position", position + Vector2(0, 0), .3)
	mariotween.chain().tween_property(self, "position", position + Vector2(140, 0), 2).finished
	await mariotween.finished
	SceneManager.change_scene("res://Scenes/castle_scenept_2.tscn", {"pattern": "diagonal", "speed": 4})
