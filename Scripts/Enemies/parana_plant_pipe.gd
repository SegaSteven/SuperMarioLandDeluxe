extends StaticBody2D

class_name ParanhaPlantPipe

signal player_touched_paranha

# Parana Plant -----------------------------------------------------------------
@onready var paranha_plant: Area2D = $ParanhaPlant
@onready var animated_sprite_2d: AnimatedSprite2D = $ParanhaPlant/AnimatedSprite2D


# Areas ------------------------------------------------------------------------
@onready var top_area: Area2D = $"Top area"
@onready var right_area: Area2D = $RightArea
@onready var left_area: Area2D = $LeftArea
@onready var player: Player = $"../../Player"

var mario_near = false

# Called when the node enters the scene tree for the first time.
func _ready():
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_process(true)
	print("started")

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	set_process(false)
	print("stopped")


func _on_paranha_plant_area_entered(area: Area2D) -> void:
	player_touched_paranha.emit()
	paranha_plant.set_collision_mask_value(1, false)
