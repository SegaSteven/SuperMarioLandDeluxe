extends CanvasLayer

class_name WorldUI

#references
@onready var level_name = $LevelName
@onready var world_area = $WorldArea
@onready var lives: Label = $Lives
@onready var mario_map: AnimatedSprite2D = $MarioMap
@onready var OWplayer = preload("res://Scripts/World_Scripts/overworld_player.gd")

var leveltile = OverworldTile
var currentarea = OverworldMan.area_name


func _process(delta):
	_on_interactive_overworld_tile_levelname(update_level_name)
	_on_interactive_overworld_tile_areaname(update_area_name)
	#GameManager.gain_life.connect(update_lives)
	#OverworldMan.areanamedata.connect(update_area_name)
	
func update_level_name():
	level_name.text = str(OverworldMan.level_name)
	
func update_lives():
	lives.text = str(GameManager.lives)
	
func update_area_name():
	world_area.text = str(OverworldMan.area_name)


func _on_interactive_overworld_tile_levelname(String: Variant):
	level_name.text = str(OverworldMan.level_name)

func _on_interactive_overworld_tile_areaname(String: Variant):
	world_area.text = str(OverworldMan.area_name)
