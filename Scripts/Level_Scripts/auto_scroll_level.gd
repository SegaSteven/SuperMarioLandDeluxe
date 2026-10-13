extends LevelData

class_name AutoScrollLevel
## Level script for auto-scrolling vehicle stages (Marine Pop submarine, Sky Pop plane).
## Puts Mario into his "Vehicle" state as soon as the level starts. Use the template scene
## Scenes/Levels/Templates/marine_pop_template.tscn - duplicate it and build your level in it.

@export var vehicle_state: StringName = &"Vehicle"
@export var start_in_vehicle: bool = true

@onready var camera: Camera2D = get_node_or_null("Camera2D")
@onready var flash: CanvasItem = get_node_or_null("Camera2D/Flash")
@onready var ui_node: Node = get_node_or_null("Camera2D/UI")
@onready var pause_sfx: AudioStreamPlayer = get_node_or_null("Pause/PauseSFX")


func _ready() -> void:
	if pause_label:
		pause_label.hide()
	GameManager.start_level()
	if start_in_vehicle and player:
		await get_tree().process_frame   # let Mario finish setting up first
		player.state_machine.transition_to(vehicle_state)
	if player:
		player.super_mode_play.connect(_on_player_super_mode_play)
		player.super_mode_stop.connect(_on_player_super_mode_stop)
	if flash:
		flash.visible = true
		flash.modulate.a = 1.0
		create_tween().tween_property(flash, "modulate:a", 0.0, 0.2)
	if level_music and not level_music.playing:
		level_music.play()
	level_start.emit()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if pause_sfx:
			pause_sfx.play()
		swap_pause_state()


func _on_player_super_mode_play() -> void:
	if level_music:
		level_music.stop()


func _on_player_super_mode_stop() -> void:
	if level_music:
		level_music.play()
