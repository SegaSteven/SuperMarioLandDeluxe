extends Area2D

class_name PranahaPlant

@export var start_time = 1
@export var paranha_plant_time = 3
@onready var player: Player = $"../../Player"

var score = 100

var rng = RandomNumberGenerator.new()
var mario_near = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	if mario_near == false:
		paranha_plant_move()
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func paranha_plant_move():
	var my_random_number = rng.randf_range(1, 4)
	var plant_tween = get_tree().create_tween().set_loops()
	plant_tween.tween_property(self, "position", position + Vector2(0,0), my_random_number)
	plant_tween.chain().tween_property(self, "position", position + Vector2(0,-16), 1)
	plant_tween.chain().tween_property(self, "position", position + Vector2(0,-16), paranha_plant_time)
	plant_tween.chain().tween_property(self, "position", position + Vector2(0,0), 1)
	plant_tween.chain().tween_property(self, "position", position + Vector2(0,0), 3)


func _on_right_area_area_entered(area: Area2D) -> void:
	mario_near = true


func _on_top_area_area_entered(area: Area2D) -> void:
	mario_near = true


func _on_left_area_area_entered(area: Area2D) -> void:
	mario_near = true


func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	set_process(true)


func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	set_process(false)


func _on_body_entered(body: Superball) -> void:
	$Enemykilled.play()
	GameManager.on_points_scored(score)
	set_collision_layer_value(9, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(7, false)
	queue_free()
