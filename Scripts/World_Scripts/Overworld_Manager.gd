extends Node2D

@export var level_name: String
@export var area_name: String
@export var level_scene_path : String
var spawn_point : Vector2


func _on_interactive_level_tile_send_area_name(area_name_send: Variant):
	area_name = area_name_send


func _on_interactive_level_tile_send_level_name(level_name_send: Variant) -> void:
	level_name = level_name_send


func _on_interactive_level_tile_send_level_path(level_scene_path_send: Variant) -> void:
	level_scene_path = level_scene_path_send
