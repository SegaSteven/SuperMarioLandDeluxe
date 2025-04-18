extends CharacterBody2D

class_name PyramidPlayer

signal on_level()
signal off_level()

@onready var animated_sprite_2d: PlayerAnimatedMapSprite = $AnimatedSprite2D
@onready var world_ui: WorldUI = $"../Camera2D/WorldUI"
@onready var level_start_text: Label = $"../Camera2D/LevelStart/LevelStartText"
@onready var level_start_black: ColorRect = $"../Camera2D/LevelStart/LevelStartBlack"
@onready var level_start: CanvasLayer = $"../Camera2D/LevelStart"
@onready var touched_tile = preload("res://Scripts/World_Scripts/LevelTiles/OverworldTile.gd")

# onready for levels
@onready var _1_3_level: PyramidTile = $"../Level Holder/_1_3 level"
@onready var come_in_right: PyramidTile = $"../Level Holder/ComeInRight"
@onready var come_in_down: PyramidTile = $"../Level Holder/ComeInDown"

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

var MoveFromRight = false
var MoveFromDown = false

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
	await get_tree().create_timer(0.6).timeout
# Come in from Down ------------------------------------------------------------------------------------
	if MoveFromDown == true:
		var move_tween = get_tree().create_tween()
		animated_sprite_2d.play("Up")
		move_tween.tween_property(self, "position", position + Vector2(0,-32), 1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-8,-32), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-8,-56), 0.6)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		MoveFromDown = false
		
		
# Come in from Right -------------------------------------------------------------------------------------
	if MoveFromRight == true:
		var move_tween = get_tree().create_tween()
		animated_sprite_2d.play("Left")
		move_tween.tween_property(self, "position", position + Vector2(-16, 0), 0.3)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-16,38), 1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-40,38), 0.8)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-40,32), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-48,32), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Up"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-48,24), 0.2)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Left"))
		move_tween.chain().tween_property(self, "position", position + Vector2(-80,24), 1)
		move_tween.tween_callback(animated_sprite_2d.play.bind("Down"))
		MoveFromRight = false
		
	
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
	if Input.is_action_just_pressed("jump") && on_level.connect(_on__1_3_level_area_entered) && input_free == true && start_active == false:
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


func _on_come_in_right_area_entered(area: Area2D) -> void:
		MoveFromRight = true
		print("InFromRight")
		levelname = come_in_right.level_name
		local_area = come_in_right.area_name
		level_path = come_in_right.level_scene_path
		OverworldMan.level_name = levelname
		OverworldMan.area_name = local_area
		OverworldMan.level_scene_path = level_path


func _on_come_in_down_area_entered(area: Area2D) -> void:
		MoveFromDown = true
		print("inFromDown")
		levelname = come_in_down.level_name
		local_area = come_in_down.area_name
		level_path = come_in_down.level_scene_path
		OverworldMan.level_name = levelname
		OverworldMan.area_name = local_area
		OverworldMan.level_scene_path = level_path
		on_level.emit("on_level")


func _on__1_3_level_area_entered(area: Area2D) -> void:
		print("entered tile 1-3")
		on_map_tile = true
		_1_3_active = true
		can_move_right = true
		can_move_down = true
		levelname = _1_3_level.level_name
		local_area = _1_3_level.area_name
		level_path = _1_3_level.level_scene_path
		OverworldMan.level_name = levelname
		OverworldMan.area_name = local_area
		OverworldMan.level_scene_path = level_path
		GameManager.spawn_point = _1_3_level.spawn_point
		on_level.emit("on_level")
