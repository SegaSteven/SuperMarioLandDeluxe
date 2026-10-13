extends Node2D

class_name EnemySpawner
## Keeps spawning a scene while it's on screen: a Bullet Biff cannon, a Ganchan rock dropper,
## a Torion fish school... Put it where things should come from.

@export var spawn_scene: PackedScene
@export var interval: float = 3.0
@export var first_delay: float = 1.0
@export var max_alive: int = 3
@export var fire_towards_player: bool = true   ## sets the spawned thing's direction towards Mario
@export var only_when_on_screen: bool = true
@export var screen_margin: float = 16.0

var _timer: float
var _alive: Array = []


func _ready() -> void:
	_timer = first_delay


func _physics_process(delta: float) -> void:
	if spawn_scene == null:
		return
	if only_when_on_screen and not _on_screen():
		return
	_timer -= delta
	if _timer > 0.0:
		return
	_timer = interval
	_alive = _alive.filter(func(n): return is_instance_valid(n))
	if _alive.size() >= max_alive:
		return
	var thing = spawn_scene.instantiate()
	thing.global_position = global_position
	if fire_towards_player and "start_direction" in thing and is_instance_valid(GameManager.player):
		thing.start_direction = 1 if GameManager.player.global_position.x > global_position.x else -1
	if "always_active" in thing:
		thing.always_active = true
	get_tree().current_scene.add_child(thing)
	_alive.append(thing)
	var sfx := get_node_or_null("SpawnSound") as AudioStreamPlayer
	if sfx:
		sfx.play()


func _on_screen() -> bool:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return true
	var half := get_viewport_rect().size.x * 0.5 / cam.zoom.x
	return absf(global_position.x - cam.get_screen_center_position().x) <= half + screen_margin
