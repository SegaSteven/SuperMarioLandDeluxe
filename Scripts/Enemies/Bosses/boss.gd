extends Enemy

class_name Boss
## Base class for bosses. Works like King Totomesu out of the box:
##   - walks back and forth in front of the switch
##   - jumps up and down every few seconds
##   - spits fireballs at Mario
##   - can't be stomped (touching it hurts Mario)
##   - takes `max_health` superballs to beat
## Like the Game Boy game, beating it with superballs knocks it out, but Mario still has to
## touch the BossSwitch behind it to finish the level. Touching the switch beats it instantly.
##
## Make your own boss by extending this and overriding _boss_behaviour(delta), or just
## change the numbers in the Inspector. Set any number to 0 to switch that attack off.

signal health_changed(current: int, maximum: int)
signal defeated(boss: Boss)

@export_group("Boss health")
@export var max_health: int = 5               ## superballs needed (King Totomesu = 5)
@export var hurt_invincibility: float = 0.4   ## seconds it can't be hurt again after a hit
@export var stomp_damage: int = 0             ## > 0 lets Mario damage it by jumping on it

@export_group("Boss movement")
@export var walk_speed: float = 15.0
@export var patrol_distance: float = 24.0     ## walks this far each way from its start (0 = stands still)
@export var jump_interval: float = 2.5        ## seconds between jumps (0 = never jumps)
@export var jump_speed: float = 160.0

@export_group("Boss hover (water / sky bosses)")
@export var hover: bool = false               ## true = no gravity, floats up and down (Dragonzamasu, Biokinton, Tatanga)
@export var hover_range: float = 32.0         ## how far up/down it floats
@export var hover_speed: float = 1.2          ## how fast it floats
@export var hover_sway_x: float = 0.0         ## also drifts left/right this far (Tatanga)

@export_group("Boss attack")
@export var projectile_scene: PackedScene     ## e.g. res://Scenes/Enemies/Bosses/boss_fireball.tscn
@export var fire_interval: float = 2.0        ## seconds between shots (0 = never shoots)
@export var fire_offset: Vector2 = Vector2(-10, -4)   ## where shots come out (x is flipped to face Mario)
@export var shots_per_volley: int = 1
@export var volley_gap: float = 0.25
@export var spread_count: int = 1             ## shots per fire in a fan (Tatanga = 3)
@export var spread_angle: float = 20.0        ## degrees between shots in the fan
@export var throw_velocity: Vector2 = Vector2.ZERO   ## > 0 = lob shots in an arc instead (Hiyoihoi's boulders). x is flipped towards Mario.

@export_group("When beaten")
@export var reveal_on_defeat: Array[NodePath] = []   ## e.g. the exit door, for bosses with no switch (Marine/Sky Pop)
@export_file("*.tscn") var on_defeat_go_to: String = ""   ## e.g. your ending cutscene after Tatanga (.tscn or uid://). Empty = stay
@export var on_defeat_spawn: Vector2 = Vector2.ZERO        ## where Mario appears there (0,0 = the scene's own start)
@export var on_defeat_delay: float = 3.0                    ## seconds after the boss falls before moving on
@export var on_defeat_finishes_level: bool = true          ## mark the level beaten and save star coins first

@export_group("Animations")
@export var anim_walk: StringName = &"walk"
@export var anim_jump: StringName = &"jump"
@export var anim_attack: StringName = &"attack"
@export var anim_hurt: StringName = &"hurt"

var health: int
var is_defeated: bool = false

var _start_x: float
var _jump_timer: float
var _fire_timer: float
var _hurt_timer: float = 0.0


func _on_ready() -> void:
	add_to_group("boss")
	health = max_health
	can_be_stomped = stomp_damage > 0
	immune_to_projectiles = false
	despawn_margin = 100000.0   # bosses never despawn behind the camera
	_start_x = global_position.x
	_hover_origin = global_position
	for path in reveal_on_defeat:
		var n := get_node_or_null(path)
		if n:
			n.visible = false
			n.process_mode = Node.PROCESS_MODE_DISABLED
	_jump_timer = jump_interval
	_fire_timer = fire_interval
	_boss_ready()


## Override in your own boss for extra setup.
func _boss_ready() -> void:
	pass


var _hover_time: float = 0.0
var _hover_origin: Vector2


func _alive_physics(delta: float) -> void:
	_hurt_timer = maxf(_hurt_timer - delta, 0.0)
	if hover:
		_hover_time += delta
		global_position = _hover_origin + Vector2(
			sin(_hover_time * hover_speed * 0.5) * hover_sway_x,
			sin(_hover_time * hover_speed) * hover_range * 0.5)
		_face(direction_to_player())
		_attack_timers(delta)
		return
	apply_gravity(delta)
	_boss_behaviour(delta)
	move_and_slide()


func _attack_timers(delta: float) -> void:
	if fire_interval > 0.0 and projectile_scene != null:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_interval
			_fire_volley()


## Default behaviour (King Totomesu). Override this for a different boss.
func _boss_behaviour(delta: float) -> void:
	# Walk back and forth
	if patrol_distance > 0.0:
		if global_position.x <= _start_x - patrol_distance:
			direction = 1
		elif global_position.x >= _start_x + patrol_distance:
			direction = -1
		velocity.x = direction * walk_speed
	else:
		velocity.x = 0.0
	# Always look at Mario
	_face(direction_to_player())

	if is_on_floor():
		_play_anim(anim_walk)

	# Jump
	if jump_interval > 0.0:
		_jump_timer -= delta
		if _jump_timer <= 0.0 and is_on_floor():
			velocity.y = -jump_speed
			_jump_timer = jump_interval
			_play_anim(anim_jump)

	# Shoot
	if fire_interval > 0.0 and projectile_scene != null:
		_fire_timer -= delta
		if _fire_timer <= 0.0:
			_fire_timer = fire_interval
			_fire_volley()


func _fire_volley() -> void:
	_play_anim(anim_attack)
	for i in shots_per_volley:
		if is_defeated or not is_inside_tree():
			return
		shoot_projectile()
		if i < shots_per_volley - 1:
			await get_tree().create_timer(volley_gap).timeout


## Spawns one projectile aimed at Mario's side. Call it from your own boss too.
func shoot_projectile(aim_at_player: bool = false) -> Node2D:
	if projectile_scene == null:
		return null
	var dir := direction_to_player()
	var first: Node2D = null
	for i in spread_count:
		var shot = projectile_scene.instantiate()
		shot.global_position = global_position + Vector2(absf(fire_offset.x) * dir, fire_offset.y)
		if "direction" in shot:
			shot.direction = dir
		if "start_direction" in shot:
			shot.start_direction = dir
		if throw_velocity != Vector2.ZERO and "launch_velocity" in shot:
			shot.launch_velocity = Vector2(absf(throw_velocity.x) * dir, throw_velocity.y)
		elif spread_count > 1 and "launch_velocity" in shot:
			var angle := deg_to_rad((i - (spread_count - 1) * 0.5) * spread_angle)
			var spd: float = shot.speed if "speed" in shot else 70.0
			shot.launch_velocity = Vector2(dir * spd, 0).rotated(angle * dir)
		elif aim_at_player and "aim_at" in shot and get_player():
			shot.aim_at = get_player().global_position
		get_tree().current_scene.add_child(shot)
		if first == null:
			first = shot
	_play_sfx("BossFire")
	return first


# --- Taking damage ------------------------------------------------------------
func hit_by_projectile(_ball: Node) -> void:
	take_damage(1)


func stomp(_player: Node) -> void:
	if stomp_damage > 0:
		take_damage(stomp_damage)


## Star, block bumps and Nokobon explosions only take 1 health instead of killing outright.
func die_from_hit(_from_direction: float = 1.0) -> void:
	take_damage(1)


func take_damage(amount: int) -> void:
	if is_defeated or _hurt_timer > 0.0:
		return
	health = maxi(health - amount, 0)
	_hurt_timer = hurt_invincibility
	health_changed.emit(health, max_health)
	_play_sfx("BossHit")
	_play_anim(anim_hurt)
	var flash := create_tween().set_loops(3)
	flash.tween_property(self, "modulate:a", 0.2, 0.05)
	flash.tween_property(self, "modulate:a", 1.0, 0.05)
	if health <= 0:
		defeat()


## Knocks the boss out (it flips over and falls off-screen). Safe to call more than once.
func defeat() -> void:
	if is_defeated:
		return
	is_defeated = true
	defeated.emit(self)
	if on_defeat_go_to != "":
		_go_after_defeat()
	for path in reveal_on_defeat:
		var n := get_node_or_null(path)
		if n:
			n.visible = true
			n.process_mode = Node.PROCESS_MODE_INHERIT
	super.die_from_hit(float(-direction_to_player()))


func _go_after_defeat() -> void:
	var scene := on_defeat_go_to
	var spawn := on_defeat_spawn
	var finish := on_defeat_finishes_level
	# A tree timer, so it still fires after this boss has fallen off-screen and been freed
	get_tree().create_timer(on_defeat_delay, false).timeout.connect(func():
		if finish:
			GameManager.win()
		GameManager.travel_to(scene, spawn, {"pattern": "squares", "speed": 4}))
