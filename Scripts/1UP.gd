extends Area2D

class_name LifeHeart

@onready var shape_case_2d = $ShapeCast2D

@export var score = 100

func _ready():
	$Blockhititem.play()
	var die_tween = get_tree().create_tween()
	die_tween.tween_property(self, "position", position + Vector2(3, -10), .04)
	die_tween.chain().tween_property(self, "position", position + Vector2(5, -11), .08)
	die_tween.chain().tween_property(self, "position", position + Vector2(8, -13), .06)
	die_tween.chain().tween_property(self, "position", position + Vector2(15, -14), .1)
	die_tween.chain().tween_property(self, "position", position + Vector2(20, -12), .08)
	die_tween.chain().tween_property(self, "position", position + Vector2(25, -9), .1)
	die_tween.chain().tween_property(self, "position", position + Vector2(25, 500), 10)
	

func _on_area_entered(area):
	if area.get_parent() is Player:
		GameManager.on_life_collected(1)
		GameManager.score += score
		queue_free()
