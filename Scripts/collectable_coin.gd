extends Area2D

class_name CollectableCoin

@export var score = 100
@export var coins = 1

	
func _on_body_entered(body: Player):
	$Sprite2D.hide()
	GameManager.on_coin_collected(coins)
	GameManager.on_points_scored(score)
	$AudioStreamPlayer.play()
	await get_tree().create_timer(0.3).timeout
	queue_free()
		
