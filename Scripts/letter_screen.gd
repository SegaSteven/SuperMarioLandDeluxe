extends Node2D


@export var next_scene = "res://Scenes/WorldScenes/world_map.tscn"
@onready var black_fade = $BlackFade
@onready var press_start = $PressStart
@export var spawn_point: Vector2

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	press_start.hide()
	var tween = get_tree().create_tween()
	tween.tween_property(black_fade, "modulate:a", 1, 0.2)
	tween.chain().tween_property(black_fade, "modulate:a", 0, 2).finished

	await get_tree().create_timer(8).timeout
	press_start.show()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Start"):
		OverworldMan.spawn_point = spawn_point
		SceneManager.change_scene(next_scene, {"pattern": "squares", "speed": 4})
	await get_tree().create_timer(10).timeout
	OverworldMan.spawn_point = spawn_point
	SceneManager.change_scene(next_scene, {"pattern": "squares", "speed": 4})
