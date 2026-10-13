extends CharacterBody2D

class_name Enemy
## Base class for everything that hurts Mario.
##
## TO MAKE A NEW ENEMY:
##   1. New scene: CharacterBody2D (root) + CollisionShape2D + AnimatedSprite2D
##      (+ optional AudioStreamPlayer named "Enemykilled").
##   2. Attach a script that `extends Enemy`.
##   3. Override only what's different. The most useful overrides:
##        _alive_physics(delta)   - how it moves each frame
##        stomp(player)           - what happens when Mario lands on it
##        touch_player(player)    - what happens when Mario touches it from the side
##        hit_by_projectile(ball) - what a superball does
##   Everything else (gravity, turning at walls, waking up near the camera, dying,
##   points, despawning) is handled here.

signal killed(enemy: Enemy)

@export_group("Behaviour")
@export var score: int = 100
@export var horizontal_speed: float = 20.0      ## walking speed in px/s (always positive)
@export var start_direction: int = -1           ## -1 = walks left, 1 = walks right
@export var turn_at_ledges: bool = false        ## true = turns round instead of walking off edges
@export var can_be_stomped: bool = true
@export var immune_to_projectiles: bool = false
@export var immune_to_superballs: bool = false   ## superballs pass through, torpedoes still work (Honen)
@export var hits_to_kill: int = 1               ## superballs/torpedoes needed (Yurarin = 2)
@export var sprite_faces_left: bool = true      ## true if your art looks left by default

@export_group("Physics")
@export var gravity: float = 400.0
@export var max_fall_speed: float = 250.0

@export_group("Waking up")
@export var always_active: bool = false
@export var wake_margin: float = 24.0           ## px outside the screen edge where it wakes up
@export var despawn_margin: float = 64.0        ## px behind the camera before it deletes itself
@export var fall_limit_y: float = 600.0         ## deletes itself below this y

## Current walking/flying direction. Set it before adding the enemy to override start_direction.
var direction: int = 0
var is_dead: bool = false
var _hits_taken: int = 0
var _active: bool = false

var sprite: AnimatedSprite2D
var body_shape: CollisionShape2D


func _ready() -> void:
	add_to_group("enemy")
	if direction == 0:
		direction = start_direction
	_find_nodes()
	_configure_collision()
	_face(direction)
	_on_ready()


## Override instead of _ready() in your own enemy so the base setup always runs.
func _on_ready() -> void:
	pass


func _find_nodes() -> void:
	for child in get_children():
		if sprite == null and child is AnimatedSprite2D:
			sprite = child
		if body_shape == null and child is CollisionShape2D:
			body_shape = child


## Enemies only collide with the world. Mario finds them with his own Area2D.
func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY)
	collision_mask = Layers.WORLD_MASK


# =============================================================================
# Main loop
# =============================================================================
func _physics_process(delta: float) -> void:
	_update_activation()
	if is_dead:
		_dead_physics(delta)
		return
	if not _active:
		return
	_alive_physics(delta)


## Default behaviour: a walker (Goomba style). Override for anything else.
func _alive_physics(delta: float) -> void:
	apply_gravity(delta)
	velocity.x = direction * horizontal_speed
	move_and_slide()
	_turn_if_blocked()


func apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y = minf(velocity.y + gravity * delta, max_fall_speed)
	elif velocity.y > 0.0:
		velocity.y = 0.0


func _turn_if_blocked() -> void:
	if is_on_wall():
		var wall_x := get_wall_normal().x
		if wall_x != 0.0:
			direction = 1 if wall_x > 0.0 else -1
			_face(direction)
	elif turn_at_ledges and is_on_floor() and _ledge_ahead():
		direction = -direction
		_face(direction)


func _ledge_ahead() -> bool:
	var half_width := 4.0
	var t := global_transform.translated(Vector2(direction * (half_width + 2.0), 0))
	return not test_move(t, Vector2(0, 6))


func _face(dir: int) -> void:
	if sprite == null:
		return
	var looking_left := dir < 0
	sprite.flip_h = (not looking_left) if sprite_faces_left else looking_left


# =============================================================================
# Waking up / despawning (based on the camera, no notifier nodes needed)
# =============================================================================
func _update_activation() -> void:
	if global_position.y > fall_limit_y:
		queue_free()
		return
	var cam := get_viewport().get_camera_2d()
	if cam == null or always_active:
		_active = true
		return
	var half_width := get_viewport_rect().size.x * 0.5 / cam.zoom.x
	var cam_x := cam.get_screen_center_position().x
	var dx := global_position.x - cam_x
	if not _active and absf(dx) <= half_width + wake_margin:
		_active = true
		_on_activated()
	elif _active and dx < -(half_width + despawn_margin):
		queue_free()


func _on_activated() -> void:
	pass


# =============================================================================
# How Mario / projectiles interact with enemies
# =============================================================================
## False while dying: Mario ignores the enemy completely.
func is_interactable() -> bool:
	return not is_dead and _active


## Called by Mario when he lands on the enemy's head. Default: squash it flat.
func stomp(_player: Node) -> void:
	die_flat()


## Called when Mario touches the enemy and it was not a stomp. Default: hurts Mario.
func touch_player(player: Node) -> void:
	if player.has_method("hurt"):
		player.hurt(self)


## Superball / torpedo hit. Override for special reactions (e.g. Gunion splitting).
func hit_by_projectile(ball: Node) -> void:
	if not takes_projectile(ball):
		return
	_hits_taken += 1
	if _hits_taken < hits_to_kill:
		_flash_hit()
		return
	var dir := 1.0
	if ball != null and "velocity" in ball:
		dir = signf(ball.velocity.x)
	die_from_hit(dir if dir != 0.0 else 1.0)


## True if this projectile can hurt the enemy (superballs and torpedoes check this).
func takes_projectile(ball: Node) -> bool:
	if immune_to_projectiles:
		return false
	if immune_to_superballs and ball is Superball:
		return false
	return true


func _flash_hit() -> void:
	var tween := create_tween().set_loops(2)
	tween.tween_property(self, "modulate:a", 0.3, 0.05)
	tween.tween_property(self, "modulate:a", 1.0, 0.05)


## Y coordinate of the top of the enemy's body. Mario compares his feet to this.
func get_top_y() -> float:
	if body_shape == null or body_shape.shape == null:
		return global_position.y - 4.0
	return body_shape.global_position.y - _shape_half_height(body_shape.shape)


func _shape_half_height(shape: Shape2D) -> float:
	if shape is RectangleShape2D:
		return shape.size.y * 0.5
	if shape is CircleShape2D:
		return shape.radius
	if shape is CapsuleShape2D:
		return shape.height * 0.5
	return 4.0


# =============================================================================
# Dying
# =============================================================================
## Stomped: stays where it is, shows the "dead" frame, disappears after a moment.
func die_flat(remove_after: float = 1.0) -> void:
	if is_dead:
		return
	_begin_death()
	velocity = Vector2.ZERO
	_play_anim("dead")
	_play_sfx("Enemykilled")
	award_score()
	get_tree().create_timer(remove_after).timeout.connect(queue_free)


## Knocked out (superball, star, block bump): flips upside down and tumbles off screen.
func die_from_hit(from_direction: float = 1.0) -> void:
	if is_dead:
		return
	_begin_death()
	collision_mask = 0
	velocity = Vector2(signf(from_direction) * 50.0, -110.0)
	if sprite:
		sprite.flip_v = true
	_play_anim("dead")
	_play_sfx("Enemykilled")
	award_score()
	get_tree().create_timer(4.0).timeout.connect(queue_free)


func _begin_death() -> void:
	is_dead = true
	_active = true   # keep processing so the death animation plays even if off-screen
	killed.emit(self)


func _dead_physics(delta: float) -> void:
	# Squashed enemies sit still; knocked-out ones (collision_mask == 0) tumble.
	if collision_mask == 0:
		velocity.y += gravity * delta
		position += velocity * delta


func award_score(amount: int = -1) -> void:
	var points := score if amount < 0 else amount
	if points <= 0:
		return
	GameManager.on_points_scored(points)
	var label = preload("res://Scenes/points_label.tscn").instantiate()
	label.score = points
	label.position = global_position + Vector2(-10, -25)
	get_tree().current_scene.add_child(label)


# =============================================================================
# Small helpers
# =============================================================================
func _play_anim(anim_name: String) -> void:
	if sprite and sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)


func _play_sfx(node_name: String) -> void:
	var player := get_node_or_null(node_name) as AudioStreamPlayer
	if player:
		player.play()


func get_player() -> Node2D:
	if is_instance_valid(GameManager.player):
		return GameManager.player
	return get_tree().get_first_node_in_group("player") as Node2D


## -1 if Mario is to the left of this enemy, 1 if to the right.
func direction_to_player() -> int:
	var p := get_player()
	if p == null:
		return direction
	return 1 if p.global_position.x > global_position.x else -1


# =============================================================================
# Old signal handler names that your enemy scenes are still connected to.
# They no longer do anything (activation is camera based now) but keep the scenes loading
# without "method not found" errors. Delete the connections in the editor when you tidy up.
# =============================================================================
func _on_visible_on_screen_notifier_2d_screen_entered() -> void:
	pass

func _on_visible_on_screen_notifier_2d_screen_exited() -> void:
	pass

func _on_visible_on_screen_notifier_2d_2_screen_entered() -> void:
	pass

func _on_visible_on_screen_notifier_2d_2_screen_exited() -> void:
	pass

func _on_hitbox_body_entered(_body: Node2D) -> void:
	pass

func _on_goomba_body_entered(_body: Node2D) -> void:
	pass

func _on_body_entered(_body: Node2D) -> void:
	pass

func _on_area_2d_body_entered(_body: Node2D) -> void:
	pass
