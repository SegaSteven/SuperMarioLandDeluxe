extends Sprite2D



@onready var sea_sprite = $"."

func _ready():
	var region_rect = Rect2(sea_sprite.region_rect)
	region_rect.size = Vector2(1800, 800)
	sea_sprite.region_rect = region_rect
	sea_sprite.position = Vector2(-8, 0)
