extends CharacterBody2D

class_name Superball
## Mario's superball: bounces along the ground, ricochets off walls, kills enemies it touches.

@export var horizontal_speed: float = 110.0
@export var bounce_speed: float = 100.0
@export var gravity: float = 500.0
@export var lifetime: float = 4.0
@export var bounce_off_walls: bool = true

var direction: int = 1      # set by the player before the ball is added to the scene
var _hit: bool = false


func _ready() -> void:
	add_to_group("superball")
	collision_layer = Layers.bit(Layers.FIREBALL)
	collision_mask = Layers.WORLD_MASK          # only bounces off the world, never off enemies

	var hit_area := get_node_or_null("Area2D") as Area2D
	if hit_area:
		hit_area.collision_layer = Layers.bit(Layers.FIREBALL)
		hit_area.collision_mask = Layers.bit(Layers.ENEMY) | Layers.bit(Layers.PLANT)

	velocity = Vector2(horizontal_speed * direction, 40.0)
	var sfx := get_node_or_null("Fireball") as AudioStreamPlayer
	if sfx:
		sfx.play()
	get_tree().create_timer(lifetime).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	move_and_slide()
	if is_on_floor():
		velocity.y = -bounce_speed
	elif is_on_ceiling():
		velocity.y = absf(velocity.y)
	if is_on_wall():
		if bounce_off_walls:
			direction = -direction
			velocity.x = horizontal_speed * direction
		else:
			queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	if _hit:
		return
	if body is Enemy and not body.is_dead:
		var hurt: bool = body.takes_projectile(self)
		body.hit_by_projectile(self)
		if hurt:
			_hit = true
			queue_free()


# Connected in superball.tscn - kept so the scene loads without errors.
func _on_area_2d_body_entered2(_body: Node2D) -> void:
	pass

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	queue_free()
