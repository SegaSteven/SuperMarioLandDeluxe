extends StaticBody2D

class_name MovingPlatform

@export var length = 24
@export var path: Path2D

@onready var collision_shape_2d = $AnimatableBody2D/CollisionShape2D
@onready var platform_sprite = $AnimatableBody2D/PlatformSprite

func _ready():
	var region_rect = Rect2(platform_sprite.region_rect)
	region_rect.size = Vector2(length, 8)
	platform_sprite.region_rect = region_rect
	platform_sprite.position = Vector2(-8, 0)

	var shape = RectangleShape2D.new()
	shape.size = Vector2(length, 8)
	collision_shape_2d.shape = shape
	collision_shape_2d.position = Vector2(-8, 0)
