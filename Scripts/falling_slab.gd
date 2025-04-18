extends Area2D

signal slab_hit

@onready var ray_cast_2d: RayCast2D = $RayCast2D
@onready var collision_shape_2d: CollisionShape2D = $CollisionShape2D

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if ray_cast_2d.is_colliding():
		slab_tween()

func slab_tween():
	var slab_tween = get_tree().create_tween()
	slab_tween.tween_property(self, "position", position + Vector2(0,0), 1)
	slab_tween.chain().tween_property(self, "position", position + Vector2(0, 200), 3)

func _on_area_entered(area: Area2D) -> void:
	slab_hit.emit()
