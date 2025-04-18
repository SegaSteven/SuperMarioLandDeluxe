extends AnimatedSprite2D

@export var score = 100
@export var coins = 1

func _ready():
	$Coin.play()
	var coin_tween = get_tree().create_tween()
	coin_tween.tween_property(self, "position", position + Vector2(0,0), .0)
	coin_tween.chain().tween_property(self, "position", position + Vector2(0, -20), .3)
	coin_tween.tween_callback(queue_free)
	GameManager.on_coin_collected(coins)
	GameManager.on_points_scored(score)
