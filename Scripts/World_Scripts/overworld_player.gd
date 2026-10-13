extends CharacterBody2D

class_name OverworldPlayer
## Mario on the overworld map. He stands on a MapNode. Press a direction and, if that node has
## a MapPath going that way, he walks along it to the next node. Press jump on a level to enter it.
## You never edit this to add levels: just add MapNodes and MapPaths in the map scene.

signal on_level()
signal off_level()
signal arrived(node: MapNode)
signal revealed_paths()

@export_node_path("Node2D") var start_node: NodePath    ## where Mario starts the very first time
@export var idle_animation: StringName = &"Down"
@export var snap_to_pixels: bool = true                 ## move in whole pixels like the Game Boy
@export var debug_unlock_all: bool = false              ## ignore all path locks while testing

@onready var animated_sprite_2d: AnimatedSprite2D = $AnimatedSprite2D
@onready var level_start: CanvasLayer = get_node_or_null("../Camera2D/LevelStart")
@onready var level_start_text: Label = get_node_or_null("../Camera2D/LevelStart/LevelStartText")
@onready var level_start_black: ColorRect = get_node_or_null("../Camera2D/LevelStart/LevelStartBlack")
@onready var coin_sound: AudioStreamPlayer = get_node_or_null("../Camera2D/Coin")
@onready var map_music: AudioStreamPlayer = get_node_or_null("../WorldMapMusic")

var current_node: MapNode = null
var input_free: bool = true

var _moving: bool = false
var _route: PackedVector2Array
var _anims: PackedStringArray
var _leg: int = 1
var _speed: float = 40.0
var _destination: MapNode = null


func _ready() -> void:
	if level_start:
		level_start.visible = false
	if level_start_black:
		level_start_black.self_modulate.a = 0.0
	if level_start_text:
		level_start_text.self_modulate.a = 0.0

	# Wait one frame so every MapNode has joined its group
	await get_tree().process_frame
	_place_on_starting_node()
	await _play_reveals()


func _place_on_starting_node() -> void:
	var node: MapNode = null

	# 1. Back from a level: stand on the tile we entered it from
	if OverworldMan.last_node_name != "":
		node = _find_node_by_name(OverworldMan.last_node_name)
	# 2. Arriving from another map (or a door that set a position): closest node to that spot
	if node == null and OverworldMan.spawn_point != Vector2.ZERO:
		node = _nearest_node(OverworldMan.spawn_point)
	OverworldMan.spawn_point = Vector2.ZERO
	# 3. The start node set on this player
	if node == null and not start_node.is_empty():
		node = get_node_or_null(start_node) as MapNode
	# 4. Whatever is closest to where the player was placed in the editor
	if node == null:
		node = _nearest_node(global_position)

	if node == null:
		push_warning("OverworldPlayer: no MapNode found in this scene. Add some MapNodes!")
		return
	_stand_on(node)


func _physics_process(delta: float) -> void:
	if _moving:
		_advance(delta)
		return
	if not input_free or current_node == null:
		return

	if Input.is_action_just_pressed("Up"):
		_try_walk(MapPath.Dir.UP)
	elif Input.is_action_just_pressed("down"):
		_try_walk(MapPath.Dir.DOWN)
	elif Input.is_action_just_pressed("left"):
		_try_walk(MapPath.Dir.LEFT)
	elif Input.is_action_just_pressed("right"):
		_try_walk(MapPath.Dir.RIGHT)
	elif Input.is_action_just_pressed("jump"):
		_press_confirm()


# =============================================================================
# Secret path reveals
# =============================================================================
## Any path whose unlock was just earned (secret exit, Star Road) reveals itself now, one by one.
func _play_reveals() -> void:
	var to_reveal: Array = []
	for p in get_tree().get_nodes_in_group("map_paths"):
		if p.wants_reveal():
			to_reveal.append(p)
	if to_reveal.is_empty():
		return
	input_free = false
	for p in to_reveal:
		await p.reveal()
		OverworldMan.pending_reveals.erase(p.required_unlock)
	input_free = true
	revealed_paths.emit()


# =============================================================================
# Walking
# =============================================================================
func _try_walk(dir: int) -> void:
	var link := current_node.get_link(dir)
	if link.is_empty():
		return
	var path: MapPath = link["path"]
	if not debug_unlock_all and not path.is_open(link["backwards"]):
		return

	var route := path.build_route(link["backwards"])
	_route = route["points"]
	_anims = route["anims"]
	_speed = path.speed
	_destination = link["target"] as MapNode
	_leg = 1
	_moving = true
	off_level.emit()
	path.play_trigger_animation()
	_play_leg_animation()


func _advance(delta: float) -> void:
	var step := _speed * delta
	while step > 0.0 and _leg < _route.size():
		var goal := _route[_leg]
		var dist := global_position.distance_to(goal)
		if dist <= step:
			global_position = goal
			step -= dist
			_leg += 1
			if _leg < _route.size():
				_play_leg_animation()
		else:
			global_position += global_position.direction_to(goal) * step
			step = 0.0

	if snap_to_pixels and _leg < _route.size():
		global_position = global_position.round()

	if _leg >= _route.size():
		_moving = false
		_stand_on(_destination)
		_on_arrived()


func _play_leg_animation() -> void:
	if _leg < _anims.size() and _anims[_leg] != "" and animated_sprite_2d.sprite_frames.has_animation(_anims[_leg]):
		animated_sprite_2d.play(_anims[_leg])


func _stand_on(node: MapNode) -> void:
	current_node = node
	global_position = node.global_position
	var idle := node.idle_animation if node.idle_animation != &"" else idle_animation
	if animated_sprite_2d.sprite_frames.has_animation(idle):
		animated_sprite_2d.play(idle)

	OverworldMan.level_name = node.level_name
	OverworldMan.area_name = node.area_name
	OverworldMan.level_scene_path = node.level_scene_path
	OverworldMan.last_node_name = String(node.name)
	OverworldMan.current_star_coin_total = node.star_coins_in_level if node.is_level() else 0
	if node.is_level():
		GameManager.spawn_point = node.spawn_point
	on_level.emit()


func _on_arrived() -> void:
	arrived.emit(current_node)
	if current_node.goto_scene != "" and current_node.auto_goto:
		_go_to_other_map()


# =============================================================================
# Entering levels / other maps
# =============================================================================
func _press_confirm() -> void:
	if current_node.goto_scene != "":
		_go_to_other_map()
	elif current_node.is_level() and current_node.can_enter():
		_enter_level()


func _go_to_other_map() -> void:
	input_free = false
	OverworldMan.spawn_point = current_node.goto_spawn_point
	OverworldMan.last_node_name = ""   # node names belong to this map, not the next one
	await get_tree().create_timer(0.5).timeout
	SceneManager.change_scene(current_node.goto_scene, {"pattern": "circle", "speed": 4})


func _enter_level() -> void:
	input_free = false
	GameManager.current_checkpoint = null
	GameManager.clear_pending_star_coins()
	GameManager.spawn_point = current_node.spawn_point
	var level_path := current_node.level_scene_path

	animated_sprite_2d.play("Enter")
	if level_start:
		level_start.visible = true
	if coin_sound:
		coin_sound.play()
	if map_music:
		map_music.stop()

	await get_tree().create_timer(0.4).timeout
	if level_start_black:
		level_start_black.self_modulate.a = 1.0
		var tween := create_tween()
		tween.tween_property(level_start_black, "modulate:a", 0.0, 0.0)
		tween.chain().tween_property(level_start_black, "modulate:a", 1.0, 0.15)
	await get_tree().create_timer(0.4).timeout
	if level_start_text:
		level_start_text.self_modulate.a = 1.0
	await get_tree().create_timer(0.8).timeout
	SceneManager.change_scene(level_path, {"pattern": "squares", "speed": 6})


# =============================================================================
# Helpers
# =============================================================================
func _nearest_node(pos: Vector2) -> MapNode:
	var best: MapNode = null
	var best_dist := INF
	for n in get_tree().get_nodes_in_group("map_nodes"):
		var d := (n as Node2D).global_position.distance_to(pos)
		if d < best_dist:
			best_dist = d
			best = n as MapNode
	return best


func _find_node_by_name(node_name: String) -> MapNode:
	for n in get_tree().get_nodes_in_group("map_nodes"):
		if String(n.name) == node_name:
			return n as MapNode
	return null
