extends AnimatedSprite2D

signal inplane

enum PlayerMode {
	SMALL,
	BIG
}

var player_mode = PlayerMode.BIG

var mario_position = self.global_position

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	
	# Animation Start
	play("%s_run" % animation_prefix)
	var mariotween = get_tree().create_tween()
	mariotween.tween_property(self, "position", position + Vector2(0, 0), .3)
	mariotween.chain().tween_property(self, "position", position + Vector2(210, 0), 2.6).finished
	await mariotween.finished
	inplane.emit()
	play("%s_fly" % animation_prefix)
	var flytween = get_tree().create_tween()
	flytween.tween_property(self, "position", position + Vector2(0, 0), 0.4)
	flytween.chain().tween_property(self, "position", position + Vector2(210, -30), 2.3).finished
	await flytween.finished
	SceneManager.change_scene("res://Scenes/title_screen.tscn", {"pattern": "diagonal", "speed": 4})

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
