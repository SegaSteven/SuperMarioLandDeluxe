extends PlayerState
## Mario in a vehicle: the Marine Pop submarine (worlds 2-3, 4-3) or the Sky Pop plane.
## Moves freely in 8 directions, no gravity, fires a projectile with the action button,
## can't leave the screen, and gets crushed if the auto-scrolling screen pushes him into a wall.
##
## Use it: put an AutoScrollLevel in charge of the level (see the template), or from any
## script call  player.state_machine.transition_to("Vehicle").
##
## Art: add an AnimatedSprite2D called "VehicleSprite" under the Player in your level (the
## template already has one). Animations it uses: "idle", "move", "shoot". Missing ones are
## skipped. Mario's normal sprite is hidden while he's in the vehicle.

@export_group("Movement")
@export var move_speed: Vector2 = Vector2(70, 60)   ## max speed left/right and up/down
@export var acceleration: float = 600.0
@export var drift: Vector2 = Vector2.ZERO           ## constant push, e.g. (0, 8) to slowly sink
@export var screen_margin: Vector2 = Vector2(8, 8)  ## how close to the screen edge Mario can go

@export_group("Weapon")
@export var projectile_scene: PackedScene = preload("res://Scenes/torpedo.tscn")
@export var max_projectiles: int = 2
@export var fire_offset: Vector2 = Vector2(10, 0)
@export var shoot_pose_time: float = 0.15

@export_group("Damage")
@export var one_hit_kill: bool = true               ## Game Boy style: any hit in the sub = lose a life
@export var crush_against_walls: bool = true

@export_group("Body")
@export var vehicle_size: Vector2 = Vector2(14, 12) ## collision box while in the vehicle
@export var sprite_node: NodePath = ^"VehicleSprite"

var _shape := RectangleShape2D.new()
var _sprite: AnimatedSprite2D
var _shoot_left: float = 0.0


func _init() -> void:
	allows_stomp = false
	allows_transform = false


func enter(_msg: Dictionary) -> void:
	player.velocity = Vector2.ZERO
	player.facing_dir = 1
	_shape.size = vehicle_size
	player.body_collision_shape.set_deferred("shape", _shape)
	player.body_collision_shape.set_deferred("position", Vector2.ZERO)
	player.area_collision_shape.set_deferred("shape", _shape)
	player.area_collision_shape.set_deferred("position", Vector2.ZERO)

	_sprite = player.get_node_or_null(sprite_node) as AnimatedSprite2D
	if _sprite:
		_sprite.show()
		player.animated_sprite_2d.hide()


func exit() -> void:
	if _sprite:
		_sprite.hide()
	player.animated_sprite_2d.show()
	player.update_collision_shapes(false)


func physics_update(delta: float) -> void:
	_shoot_left = maxf(_shoot_left - delta, 0.0)

	var input := Input.get_vector("left", "right", "Up", "down")
	var target := input * move_speed + drift
	player.velocity = player.velocity.move_toward(target, acceleration * delta)

	if Input.is_action_just_pressed("action"):
		_fire()

	player.move_and_slide()
	if _keep_on_screen():
		return   # crushed
	player.check_contacts()
	_animate(input)


func _fire() -> void:
	if projectile_scene == null:
		return
	if get_tree().get_nodes_in_group("player_projectile").size() >= max_projectiles:
		return
	var shot = projectile_scene.instantiate()
	shot.global_position = player.global_position + fire_offset
	if "direction" in shot:
		shot.direction = 1
	get_tree().current_scene.add_child(shot)
	_shoot_left = shoot_pose_time


## Keeps Mario inside the camera view. Returns true if he got crushed.
func _keep_on_screen() -> bool:
	var cam := player.get_viewport().get_camera_2d()
	if cam == null:
		return false
	var half := player.get_viewport_rect().size * 0.5 / cam.zoom
	var centre := cam.get_screen_center_position()
	var left := centre.x - half.x + screen_margin.x
	var right := centre.x + half.x - screen_margin.x
	var top := centre.y - half.y + screen_margin.y
	var bottom := centre.y + half.y - screen_margin.y

	var pos := player.global_position
	if pos.x < left:
		pos.x = left
		player.velocity.x = maxf(player.velocity.x, 0.0)
		player.global_position = pos
		# Screen edge pushing him into a wall = squashed
		if crush_against_walls and player.test_move(player.global_transform, Vector2(0.5, 0)):
			player.die(true)
			return true
	pos.x = minf(pos.x, right)
	pos.y = clampf(pos.y, top, bottom)
	player.global_position = pos
	return false


func _animate(input: Vector2) -> void:
	var sprite: AnimatedSprite2D = _sprite if _sprite else player.animated_sprite_2d
	var anim := &"shoot" if _shoot_left > 0.0 else (&"move" if input != Vector2.ZERO else &"idle")
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim):
		sprite.play(anim)


func on_hurt(_source: Node) -> bool:
	if one_hit_kill or player.player_mode == PlayerUpdated.PlayerMode.SMALL:
		player.die()
	else:
		# Optional softer rule: lose your power-up but stay in the vehicle
		player.get_node("Powerdown").play()
		player.set_mode(PlayerUpdated.PlayerMode.SMALL)
		player.body_collision_shape.set_deferred("shape", _shape)
		player.area_collision_shape.set_deferred("shape", _shape)
		player.start_iframes()
	return true
