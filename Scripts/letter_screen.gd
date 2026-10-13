extends Node2D
## Daisy's letter. Fades in, shows "press start" after a few seconds, and moves on to the map
## when Start is pressed or after `auto_continue_time` seconds - whichever comes first.
## (The old version started a new 10 second timer EVERY frame, which then tried to change
## scene 60 times a second and filled the debugger.)

@export var next_scene = "res://Scenes/WorldScenes/world_map.tscn"
@export var spawn_point: Vector2
@export var press_start_delay: float = 8.0
@export var auto_continue_time: float = 18.0

@onready var black_fade = $BlackFade
@onready var press_start = $PressStart

var _leaving: bool = false


func _ready() -> void:
	press_start.hide()
	var tween := create_tween()
	tween.tween_property(black_fade, "modulate:a", 1, 0.2)
	tween.tween_property(black_fade, "modulate:a", 0, 2)

	# One timer each, created once - not every frame
	get_tree().create_timer(press_start_delay).timeout.connect(press_start.show)
	get_tree().create_timer(auto_continue_time).timeout.connect(_continue)


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Start"):
		_continue()


func _continue() -> void:
	if _leaving or not is_inside_tree():
		return
	_leaving = true
	OverworldMan.spawn_point = spawn_point
	SceneManager.change_scene(next_scene, {"pattern": "squares", "speed": 4})
