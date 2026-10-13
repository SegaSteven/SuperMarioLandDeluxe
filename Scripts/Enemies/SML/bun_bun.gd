extends Enemy

class_name BunBun
## Bunbun: flies at Mario in a wavy line. When it passes over him it stops and drops a spear.

@export var fly_speed: float = 60.0
@export var bob_height: float = 6.0
@export var bob_speed: float = 6.0
@export var drop_range: float = 6.0           ## how close (horizontally) Mario must be to trigger a drop
@export var pause_before_drop: float = 0.5
@export var pause_after_drop: float = 0.5
@export var drop_cooldown: float = 2.0
@export var spawned_scene: PackedScene        ## the thing it drops (arrow_drop.tscn)

var _base_y: float = 0.0
var _time: float = 0.0
var _pause_left: float = 0.0
var _cooldown_left: float = 0.0
var _drop_pending: bool = false


func _init() -> void:
	score = 800   # default; the Inspector can still change it


func _on_ready() -> void:
	_base_y = global_position.y
	_play_anim("fly")


func _alive_physics(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)

	if _pause_left > 0.0:
		_pause_left -= delta
		if _pause_left <= 0.0 and _drop_pending:
			_drop_pending = false
			_drop()
			_pause_left = pause_after_drop
		return

	_time += delta
	global_position.x += direction * fly_speed * delta
	global_position.y = _base_y + sin(_time * bob_speed) * bob_height

	var p := get_player()
	if p and _cooldown_left <= 0.0 and spawned_scene != null:
		var below := p.global_position.y > global_position.y
		if below and absf(p.global_position.x - global_position.x) <= drop_range:
			_pause_left = pause_before_drop
			_drop_pending = true
			_cooldown_left = drop_cooldown


func _drop() -> void:
	var spear = spawned_scene.instantiate()
	spear.global_position = global_position + Vector2(0, 4)
	get_tree().current_scene.add_child(spear)


## Flying enemies have no floor to be squashed against: a stomp knocks them out instead.
func stomp(_player: Node) -> void:
	die_from_hit(0.0)
