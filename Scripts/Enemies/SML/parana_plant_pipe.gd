extends StaticBody2D

class_name ParanhaPlantPipe
## The pipe that holds a piranha plant. The plant (child "ParanhaPlant") does all the work now.
## The signal is kept because level scenes connect it to the Player.

signal player_touched_paranha


func _on_left_area_area_entered(_area: Area2D) -> void:
	pass

func _on_right_area_area_entered(_area: Area2D) -> void:
	pass

func _on_top_area_area_entered(_area: Area2D) -> void:
	pass

func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	pass

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	pass
