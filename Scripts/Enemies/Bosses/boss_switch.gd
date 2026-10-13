extends Area2D

class_name BossSwitch
## The switch behind the boss (Super Mario Land worlds 1-3, 2-3, 3-3).
## When Mario touches it: the boss is beaten (falls off-screen), the music stops, and anything
## in "Reveal Nodes" appears - put your exit DoorNormal there so the level can be finished.
##
## Setup:
##   1. Instance res://Scenes/Enemies/Bosses/boss_switch.tscn behind the boss.
##   2. Bosses: drag the boss node in (leave empty = every Boss in the level).
##   3. Reveal Nodes: drag the exit door in. It stays hidden and switched off until pressed.
## Pressing it also freezes the clock and counts the time left into the score (Time Bonus).

signal pressed

@export var bosses: Array[NodePath] = []
@export var reveal_nodes: Array[NodePath] = []
@export var stop_music: bool = true
@export var press_points: int = 0             ## extra points for pressing it
## Stop the clock and count the time left into the score, like reaching the exit door.
@export var time_bonus: bool = true
## Seconds to wait (boss falling) before the count starts. The clock is frozen straight away.
@export var time_bonus_delay: float = 1.5

var is_pressed: bool = false

@onready var sprite: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.bit(Layers.PLAYER)
	body_entered.connect(_on_body_entered)
	for path in reveal_nodes:
		var n := get_node_or_null(path)
		if n:
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
	if sprite and sprite.sprite_frames.has_animation("default"):
		sprite.play("default")


func _on_body_entered(body: Node2D) -> void:
	if is_pressed or not body is PlayerUpdated:
		return
	if body.is_dead:
		return
	press()


func press() -> void:
	is_pressed = true
	if sprite and sprite.sprite_frames.has_animation("pressed"):
		sprite.play("pressed")
	var sfx := get_node_or_null("PressSound") as AudioStreamPlayer
	if sfx:
		sfx.play()

	for boss in _get_bosses():
		boss.defeat()

	if stop_music:
		var music := get_tree().current_scene.get_node_or_null("LevelMusic") as AudioStreamPlayer
		if music:
			music.stop()

	if press_points > 0:
		GameManager.on_points_scored(press_points)

	for path in reveal_nodes:
		var n := get_node_or_null(path)
		if n:
			n.visible = true
			n.process_mode = Node.PROCESS_MODE_INHERIT

	pressed.emit()

	var ui: UI = UI.find(get_tree()) if time_bonus else null
	if ui:
		ui.stop_time()
		await get_tree().create_timer(time_bonus_delay, false).timeout
		await ui.tally_time_bonus()


func _get_bosses() -> Array:
	var out: Array = []
	if bosses.is_empty():
		for b in get_tree().get_nodes_in_group("boss"):
			if b is Boss:
				out.append(b)
	else:
		for path in bosses:
			var b := get_node_or_null(path)
			if b is Boss:
				out.append(b)
	return out
