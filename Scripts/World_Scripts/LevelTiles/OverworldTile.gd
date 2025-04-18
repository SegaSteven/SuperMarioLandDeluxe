extends Node2D

class_name OverworldTile

signal send_level_name(level_name)
signal send_area_name(area_name)
signal send_level_path(level_scene_path)
signal mario_move()
signal can_moveRight()
signal can_moveUp()
signal can_moveDown()
signal can_moveLeft()
signal level_finished()

@onready var overworld_player = %OverworldPlayer
@export var move_speed = 4
var mario_moving

@export var interation_enabled : bool = false
@export var level_scene_path : String
@export var spawn_point: Vector2
@export var level_name : String 
@export var area_name : String
@export var beaten : bool = false

var mario_can_move = false

@export_group("Enabled Directions")
@export var can_move_up = false
@export var can_move_down = false
@export var can_move_left = false
@export var can_move_right = false
@export_group("")

func _process(delta: float) -> void:
	if GameManager.level_finished == true:
		level_beaten()

func level_beaten():
	beaten = true
	level_finished.emit()

func _on_overworld_player_on_level():
	if mario_can_move == true:
		mario_move.emit()
	if can_move_down == true:
		can_moveDown.emit()
	if can_move_up == true:
		can_moveUp.emit()
	if can_move_left == true:
		can_moveLeft.emit()
	if can_move_right == true:
		can_moveRight.emit()
	send_level_name.emit(OverworldMan.level_name == level_name)
	send_area_name.emit(OverworldMan.area_name == area_name)
	send_level_path.emit(OverworldMan.level_scene_path == level_scene_path)
