extends CharacterBody2D

class_name OverworldPlayer

signal on_level()
signal off_level()

@onready var animated_sprite_2d: PlayerAnimatedMapSprite = $AnimatedSprite2D
@onready var world_ui: WorldUI = $"../Camera2D/WorldUI"
@onready var level_start_text: Label = $"../Camera2D/LevelStart/LevelStartText"
@onready var level_start_black: ColorRect = $"../Camera2D/LevelStart/LevelStartBlack"
@onready var level_start: CanvasLayer = $"../Camera2D/LevelStart"
@onready var touched_tile = preload("res://Scripts/World_Scripts/LevelTiles/OverworldTile.gd")

# onready for levels
@onready var start: StartTile = $"../LevelHolder/Start"
@onready var interactive_level_tile = $"../LevelHolder/InteractiveLevelTile"
@onready var interactive_level_tile_2 = $"../LevelHolder/InteractiveLevelTile2"

var input_free: bool
var levelname:String
var local_area: String
var level_path: String
@export var on_map_tile : bool = false


# level paths from tile collision -----------------------------------------------------------------
@export_group("Enabled Directions")
var can_move_up = false
var can_move_down = false
var can_move_left = false
var can_move_right = false
var mario_can_move = false
var level_finished = false
@export_group("")


# Level Paths -------------------------------------------------------------------------------------
var path_movement_right
var path_movement_left
var path_movement_up
var path_movement_down

# Level Names -------------------------------------------------------------------------------------
var start_active = false
var _1_1_active = false
var _1_2_active = false
var _1_3_active = false
var _2_1_active = false
var _2_2_active = false
var _2_3_active = false
var _3_1_active = false
var _3_2_active = false
var _3_3_active = false
var _4_1_active = false
var _4_2_active = false
var _4_3_active = false
var SR_active = false

func _ready() -> void:
	if OverworldMan.spawn_point != null && OverworldMan.spawn_point != Vector2.ZERO:
		global_position = OverworldMan.spawn_point
		
	input_free = true
	level_start.visible = false
	level_start_black.self_modulate.a = 0.0
	level_start_text.self_modulate.a = 0.0
	
func _process(delta):
	pass
	
	#var movement: Vector2 = (position - prev_position)
	#prev_position = position
	#
	#var moving_angle: float = movement.angle()
	#if Util.between(moving_angle, -TAU / 8, TAU / 8):
		#animated_sprite_2d.play("Left")
	#elif Util.between(moving_angle, TAU, / 8, 3 * TAU / 8)
		#animated_sprite_2d.play("Down")
	#elif moving_angle >= 3 * TAU / 8 or moving_angle <= -3 * TAU / 8:
		#animated_sprite_2d.play("Left")
		#animated_sprite_2d.flip_h = true
	#else:
		#animated_sprite_2d.play("Up")

# Set pan speed
var PanSpeedKey = 8
# Called when the node enters the scene tree for the first time.
func _input(event):	
	if Input.is_action_just_pressed("jump") && on_level.connect(_on_interactive_level_tiel_area_entered) && input_free == true && start_active == false:
		animated_sprite_2d.play("Enter")
		input_free = false
		level_start.visible = true
		$"../Camera2D/Coin".play()
		$"../WorldMapMusic".stop()
		await get_tree().create_timer(0.4).timeout
		level_start_black.self_modulate.a = 1.0
		var tween = get_tree().create_tween()
		tween.tween_property(level_start_black, "modulate:a", 0, 0)
		tween.chain().tween_property(level_start_black, "modulate:a", 1, 0.15).finished
		await get_tree().create_timer(0.4).timeout
		level_start_text.self_modulate.a = 1.0
		await get_tree().create_timer(0.8).timeout
		SceneManager.change_scene(level_path, {"pattern": "squares", "speed": 6})
# start ------------------------------------------------------------------------------------
	if Input.is_action_just_pressed("Up") && start_active == true && can_move_up == true:
		start_active = false
		can_move_up = false
		var move_tween = get_tree().create_tween()
		move_tween.tween_property(self, "position", position + Vector2(0, -32), 0.6).finished
		await move_tween.finished
		
	if Input.is_action_just_pressed("jump") && start_active == true:
		pass
# 1_1 --------------------------------------------------------------------------------------------
	if Input.is_action_just_pressed("right") && _1_1_active == true && can_move_right == true:
		var move_tween = get_tree().create_tween()
		animated_sprite_2d.play("Right")
		move_tween.tween_property(self, "position", position + Vector2(24, 0), 0.6)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(24,-32), 0.6)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Water_Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(24,-40), 0.4)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(24,-56), 0.6)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(24,-64), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Right"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,-64), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,-72), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Water_Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,-96), 1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Water_Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(24,-96), 0.4)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-8,-96), 0.5).finished
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		await move_tween.finished
		_1_1_active = false
		can_move_right = false
		can_move_down = false
		
	if Input.is_action_just_pressed("down") && _1_1_active == true && can_move_down == true:
		var move_tween = get_tree().create_tween()
		move_tween.tween_property(self, "position", position + Vector2(0, 32), 0.6).finished
		await move_tween.finished
		_1_1_active = false
		can_move_down = false
		can_move_right = false
		
# 1_2 ---------------------------------------------------------------------------------------------
	if Input.is_action_just_pressed("right") && _1_2_active == true && can_move_down == true:
		
		var move_tween = get_tree().create_tween()
		animated_sprite_2d.play("Right")
		move_tween.tween_property(self, "position", position + Vector2(32, 0), 0.5)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Water_Right"))
		move_tween.chain().tween_property(self, "position", position + Vector2(40,0), 0.4)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Water_Down"))
		move_tween.chain().tween_property(self, "position", position + Vector2(40,26), 0.1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		move_tween.chain().tween_property(self, "position", position + Vector2(40,32), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,32), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,40), 0.1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Water_Down"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,48), 0.1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		move_tween.chain().tween_property(self, "position", position + Vector2(32,96), 1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(8,96), 0.6)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down")).finished
		await move_tween.finished
		_1_2_active = false
		can_move_up = false
		can_move_right = false
		
	if Input.is_action_just_pressed("Up") && _1_2_active == true && can_move_up == true:
		var move_tween2 = get_tree().create_tween()
		animated_sprite_2d.play("Up")
		move_tween2.tween_property(self, "position", position + Vector2(0, -76), 3)
		await get_tree().create_timer(3.5).timeout
		SceneManager.change_scene("res://Scenes/WorldScenes/pyramid_map.tscn", {"pattern": "circle", "speed": 4})
# Handles entering a level.

#func _handle_entering_level():
	#
	## if Mario isn't touching a level tile, do nothing
	#if not touched_tile:
		#return
		#
	## if Mario is still moving, do nothing.
	#if moving:
		#return
		#
	## if no butto to enter a level is pressed, do nothing.
	#if not _enter_level_button_pressed():
		#return
		#
	## if the level tile doesn't have a level scene set, return.
	#if not touched_tile.level_scene_path:
	#return
	#
	## emit the "entered level" signal
	#entered_level.emit(touched_tile)

#func _on_interactive_overworld_tile_player_touched() -> void:
#
#func handle_level_tile_collision(collision: KinematicCollision2D):
	#if collision.get_collider() is OverworldTile:
		#if Input.is_action_just_pressed("jump"):
			#handle_overworldtile_collision()
			#
#func handle_overworldtile_collision():
	#var overworld_tile = OverworldTile
	#OverworldMan.level_name = levelname
	
func _on_start_area_entered(area: Area2D) -> void:
		print("entered tile Dock")
		on_map_tile = true
		start_active = true
		can_move_up = true
		levelname = start.level_name
		local_area = start.area_name
		level_path = start.level_scene_path
		OverworldMan.level_name = levelname
		OverworldMan.area_name = local_area
		OverworldMan.level_scene_path = level_path
		on_level.emit("on_level")

func _on_interactive_level_tiel_area_entered(area: Area2D):
		print("entered tile 1-1")
		on_map_tile = true
		_1_1_active = true
		can_move_right = true
		can_move_down = true
		levelname = interactive_level_tile.level_name
		local_area = interactive_level_tile.area_name
		level_path = interactive_level_tile.level_scene_path
		OverworldMan.level_name = levelname
		OverworldMan.area_name = local_area
		OverworldMan.level_scene_path = level_path
		GameManager.spawn_point = interactive_level_tile.spawn_point
		on_level.emit("on_level")

func _on_interactive_level_tile_2_area_entered(area: Area2D):
		print("entered tile 1-2")
		on_map_tile = true
		_1_2_active = true
		can_move_right = true
		can_move_up = true
		levelname = interactive_level_tile_2.level_name
		local_area = interactive_level_tile_2.area_name
		level_path = interactive_level_tile_2.level_scene_path
		OverworldMan.level_name = levelname
		OverworldMan.area_name = local_area
		OverworldMan.level_scene_path = level_path
		GameManager.spawn_point = interactive_level_tile_2.spawn_point
		on_level.emit("on_level")





func _on_interactive_level_tile_mario_move() -> void:
	mario_can_move = true


func _on_interactive_level_tile_can_move_down() -> void:
	can_move_down = true


func _on_interactive_level_tile_can_move_left() -> void:
	can_move_left = true


func _on_interactive_level_tile_can_move_right() -> void:
	can_move_right = true


func _on_interactive_level_tile_can_move_up() -> void:
	can_move_up = true


func _on_interactive_level_tile_level_finished() -> void:
	level_finished = true
