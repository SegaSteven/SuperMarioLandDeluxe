extends LevelData

class_name BasicLevel
## A general-purpose level script for NEW levels (switch palaces, Star Road, anything).
## Handles the start flash, music, pause and the star music swap, with no per-level code.
## Pipes and exits carry their own destinations, so you don't need a custom script per level.

@onready var flash: CanvasItem = get_node_or_null("Camera2D/Flash")
@onready var pause_sfx: AudioStreamPlayer = get_node_or_null("Pause/PauseSFX")


func _ready() -> void:
	if pause_label:
		pause_label.hide()
	GameManager.start_level()
	GameManager.respawn_player()
	if player:
		player.super_mode_play.connect(func(): if level_music: level_music.stop())
		player.super_mode_stop.connect(func(): if level_music: level_music.play())
	if flash:
		flash.visible = true
		flash.modulate.a = 1.0
		create_tween().tween_property(flash, "modulate:a", 0.0, 0.2)
	if level_music and level_music.stream and not level_music.playing:
		level_music.play()
	level_start.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if pause_sfx:
			pause_sfx.play()
		swap_pause_state()
