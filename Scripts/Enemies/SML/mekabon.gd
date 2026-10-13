extends Enemy

class_name Mekabon
## Mekabon (World 2, Muda): a robot. When Mario gets close its head flies off at him like a
## boomerang and comes back. If the head gets destroyed, the body grows a new one.
## Points: stomp the whole robot (head on) = 400; head or headless body on their own = 100 each.

@export var head_scene: PackedScene = preload("res://Scenes/Enemies/SML/mekabon_head.tscn")
@export var throw_range: float = 64.0
@export var throw_cooldown: float = 2.0
@export var regrow_time: float = 2.0
@export var whole_score: int = 400

var head: Node2D = null
var _head_on: bool = true
var _cooldown: float = 1.0


func _init() -> void:
	# defaults; the Inspector can still change them
	score = 100
	horizontal_speed = 12.0


func _alive_physics(delta: float) -> void:
	super._alive_physics(delta)
	_cooldown -= delta
	var p := get_player()
	if _head_on and _cooldown <= 0.0 and p and p.global_position.distance_to(global_position) <= throw_range:
		_throw_head()


func _throw_head() -> void:
	if head_scene == null:
		return
	_head_on = false
	_play_anim("headless")
	head = head_scene.instantiate()
	head.body = self
	head.global_position = global_position + Vector2(0, -8)
	get_tree().current_scene.add_child(head)


## The flying head calls this when it comes back.
func head_returned() -> void:
	head = null
	_head_on = true
	_cooldown = throw_cooldown
	_play_anim("walk")


## The flying head calls this when it gets destroyed.
func head_destroyed() -> void:
	head = null
	get_tree().create_timer(regrow_time, false).timeout.connect(func():
		if is_instance_valid(self) and not is_dead:
			_head_on = true
			_cooldown = throw_cooldown
			_play_anim("walk"))


func stomp(_player: Node) -> void:
	if _head_on:
		score = whole_score
	if is_instance_valid(head):
		head.queue_free()
	die_flat()
