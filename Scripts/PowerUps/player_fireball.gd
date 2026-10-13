extends CharacterBody2D

class_name PlayerFireball
## Mario's fireball (Fire Flower): bounces along the ground and burns up when it hits a wall,
## like the classic Mario games. (The Superball Flower's ball bounces off walls instead.)

@export var speed: float = 150.0
@export var bounce_speed: float = 110.0
@export var gravity: float = 600.0
@export var lifetime: float = 3.0

var direction: int = 1
var _done: bool = false


func _ready() -> void:
	add_to_group("superball")          # shares the "max_superballs on screen" limit
	add_to_group("player_projectile")
	collision_layer = Layers.bit(Layers.FIREBALL)
	collision_mask = Layers.WORLD_MASK
	var hit_area := get_node_or_null("Area2D") as Area2D
	if hit_area:
		hit_area.collision_layer = Layers.bit(Layers.FIREBALL)
		hit_area.collision_mask = Layers.bit(Layers.ENEMY) | Layers.bit(Layers.PLANT)
		hit_area.body_entered.connect(_on_hit_body)
	velocity = Vector2(direction * speed, 60.0)
	var sfx := get_node_or_null("Fire") as AudioStreamPlayer
	if sfx:
		sfx.play()
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	velocity.y += gravity * delta
	velocity.x = direction * speed
	move_and_slide()
	if is_on_floor():
		velocity.y = -bounce_speed
	if is_on_wall():
		_finish()


func _on_hit_body(body: Node2D) -> void:
	if _done:
		return
	if body is Enemy and not body.is_dead:
		var hurt: bool = body.takes_projectile(self)
		body.hit_by_projectile(self)
		if hurt:
			_finish()


func _finish() -> void:
	_done = true
	queue_free()
