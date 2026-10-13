extends CharacterBody2D

class_name Torpedo
## The submarine's torpedo (or the plane's bullet). Flies straight, kills enemies,
## breaks bricks, and disappears when it hits a wall or leaves the screen.

@export var speed: float = 150.0
@export var lifetime: float = 3.0
@export var breaks_bricks: bool = true

var direction: int = 1
var _done: bool = false


func _ready() -> void:
	add_to_group("player_projectile")
	collision_layer = Layers.bit(Layers.FIREBALL)
	collision_mask = Layers.WORLD_MASK
	var hit_area := get_node_or_null("Area2D") as Area2D
	if hit_area:
		hit_area.collision_layer = Layers.bit(Layers.FIREBALL)
		hit_area.collision_mask = Layers.bit(Layers.ENEMY) | Layers.bit(Layers.PLANT)
		hit_area.body_entered.connect(_on_hit_body)
	var sprite := get_node_or_null("AnimatedSprite2D") as AnimatedSprite2D
	if sprite:
		sprite.flip_h = direction < 0
	var sfx := get_node_or_null("Fire") as AudioStreamPlayer
	if sfx:
		sfx.play()
	get_tree().create_timer(lifetime, false).timeout.connect(queue_free)


func _physics_process(delta: float) -> void:
	var hit := move_and_collide(Vector2(direction * speed * delta, 0))
	if hit:
		var target := hit.get_collider()
		if breaks_bricks and target is Brick:
			target.bump(PlayerUpdated.PlayerMode.BIG)
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
