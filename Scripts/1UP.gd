extends CharacterBody2D

class_name LifeHeart
## Extra life heart. Pops out of a block in an arc and falls away - grab it quickly!

@export var score: int = 100
@export var launch_velocity: Vector2 = Vector2(45, -140)
@export var gravity: float = 300.0


func _ready() -> void:
	collision_layer = Layers.bit(Layers.BONUS)
	collision_mask = 0
	velocity = launch_velocity
	var sfx := get_node_or_null("Blockhititem") as AudioStreamPlayer
	if sfx:
		sfx.play()


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	position += velocity * delta
	if global_position.y > 600.0:
		queue_free()


# Connected in the scene, no longer needed (Mario collects it - see Player_Updated.gd)
func _on_area_entered(_area: Area2D) -> void:
	pass

func _on_area_2d_area_entered(_area: Area2D) -> void:
	pass

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass
