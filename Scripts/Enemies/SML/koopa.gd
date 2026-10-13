extends Enemy

class_name Koopa
## Nokobon, the bomb turtle from Super Mario Land.
##   Stomp it      -> it pulls into its shell and the fuse starts (it's safe to touch now)
##   Stomp again   -> blows up straight away
##   Superball     -> blows up straight away (set superball_detonates off for an instant kill instead)
##   Explosion     -> kills every enemy inside blast_radius (other Nokobon set off a chain)
##                    and hurts Mario if he's inside hurt_radius.
## Mario can only be hurt ONCE per explosion. Big Mario shrinks, then his invincibility
## blink protects him from the rest of the blast.

enum KoopaState { WALKING, SHELL, EXPLODING }

@export_group("Bomb")
@export var fuse_time: float = 1.5            ## seconds in the shell before it explodes
@export var explosion_time: float = 0.8       ## how long the explosion stays on screen
@export var blast_radius: float = 0.0        ## enemies inside this distance are destroyed
@export var hurt_radius: float = 0.0         ## Mario inside this distance gets hurt
@export var superball_detonates: bool = true
@export var chain_delay: float = 0.15         ## gap before a neighbouring Nokobon goes off

const SHELL_SHAPE = preload("res://Resources/CollisionShapes/koopa_shell_collision_shape.tres")
const FULL_SHAPE = preload("res://Resources/CollisionShapes/koopa_full_collision_shape.tres")
const EXPLODE_SHAPE = preload("res://Resources/CollisionShapes/koopa_explode_collision_shape.tres")
const FULL_SHAPE_POSITION = Vector2(0, 1.5)
const SHELL_SHAPE_POSITION = Vector2(0, 4)
const EXPLODE_SHAPE_POSITION = Vector2(0, 3)

var state: KoopaState = KoopaState.WALKING
var _hurt_player_already: bool = false


func _on_ready() -> void:
	if body_shape:
		body_shape.shape = FULL_SHAPE


func _alive_physics(delta: float) -> void:
	if state == KoopaState.WALKING:
		super._alive_physics(delta)
		return

	apply_gravity(delta)
	velocity.x = 0.0
	move_and_slide()

	if state == KoopaState.EXPLODING:
		_blast_player()


# --- How things set it off --------------------------------------------------
func stomp(_player: Node) -> void:
	match state:
		KoopaState.WALKING:
			_enter_shell()
		KoopaState.SHELL:
			explode()


func touch_player(player: Node) -> void:
	# The shell is safe to touch. Walking Nokobon hurts; the explosion hurts via _blast_player.
	if state == KoopaState.WALKING:
		super.touch_player(player)


func hit_by_projectile(ball: Node) -> void:
	if superball_detonates and state != KoopaState.EXPLODING:
		award_score()
		explode()
	else:
		super.hit_by_projectile(ball)


## Star, block bump and other explosions: blow up (this is what makes chain reactions).
func die_from_hit(from_direction: float = 1.0) -> void:
	if state == KoopaState.EXPLODING or is_dead:
		return
	if state == KoopaState.WALKING:
		award_score()
	explode()


# --- Shell and explosion ----------------------------------------------------
func _enter_shell() -> void:
	state = KoopaState.SHELL
	award_score()
	_play_anim("dead")
	_play_sfx("Enemykilled")
	_set_shape(SHELL_SHAPE, SHELL_SHAPE_POSITION)
	get_tree().create_timer(fuse_time, false).timeout.connect(explode)


func explode() -> void:
	if state == KoopaState.EXPLODING or is_dead or not is_inside_tree():
		return
	state = KoopaState.EXPLODING
	can_be_stomped = false
	remove_from_group("enemy")
	add_to_group("koopabomb")
	_play_anim("explode")
	_play_sfx("Nokobomb")
	_set_shape(EXPLODE_SHAPE, EXPLODE_SHAPE_POSITION)

	_blast_enemies()
	_blast_player()
	get_tree().create_timer(explosion_time, false).timeout.connect(queue_free)


func _blast_enemies() -> void:
	for other in get_tree().get_nodes_in_group("enemy"):
		if other == self or not other is Enemy or other.is_dead:
			continue
		if other.global_position.distance_to(global_position) > blast_radius:
			continue
		var dir := signf(other.global_position.x - global_position.x)
		if other is Koopa:
			# Small delay so a row of Nokobon goes off one after another
			get_tree().create_timer(chain_delay, false).timeout.connect(
				func(): if is_instance_valid(other): other.die_from_hit(dir))
		else:
			other.die_from_hit(dir)


## Checked every frame of the explosion, but only ever hurts Mario once.
func _blast_player() -> void:
	if _hurt_player_already:
		return
	var p := get_player()
	if p == null or not p.has_method("hurt"):
		return
	if p.global_position.distance_to(global_position) <= hurt_radius:
		_hurt_player_already = true
		p.hurt(self)


func _set_shape(shape: Shape2D, shape_position: Vector2) -> void:
	if body_shape:
		body_shape.set_deferred("shape", shape)
		body_shape.set_deferred("position", shape_position)
