extends Enemy

class_name PranahaPlant
## Piranha plant that lives inside a pipe. Pops up, waits, goes back down.
## It stays hidden if Mario is standing right next to / on its pipe (like the Game Boy game).
## Can't be stomped; a superball removes it.

@export var start_time: float = 1.0               ## minimum wait before the first pop-up
@export var paranha_plant_time: float = 3.0       ## seconds it stays up
@export var hidden_time: float = 3.0              ## seconds it stays down
@export var rise_distance: float = 16.0
@export var rise_time: float = 1.0
@export var near_distance: float = 20.0           ## Mario this close (sideways) = plant stays hidden

enum PlantState { WAITING, RISING, UP, LOWERING }

var _state: PlantState = PlantState.WAITING
var _timer: float = 0.0
var _hidden_y: float = 0.0
var _rng := RandomNumberGenerator.new()


func _init() -> void:
	score = 100


func _on_ready() -> void:
	can_be_stomped = false
	always_active = true
	_hidden_y = position.y
	_timer = start_time + _rng.randf_range(0.0, 3.0)


## The plant only collides on the plant layer, and never with the world.
func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.PLANT)
	collision_mask = 0


func is_interactable() -> bool:
	# Fully hidden inside the pipe = harmless
	return not is_dead and position.y < _hidden_y - 2.0


func _alive_physics(delta: float) -> void:
	match _state:
		PlantState.WAITING:
			_timer -= delta
			if _timer <= 0.0 and not _player_is_near():
				_state = PlantState.RISING
				_timer = 0.0
		PlantState.RISING:
			_timer += delta
			position.y = _hidden_y - rise_distance * clampf(_timer / rise_time, 0.0, 1.0)
			if _timer >= rise_time:
				_state = PlantState.UP
				_timer = paranha_plant_time
		PlantState.UP:
			_timer -= delta
			if _timer <= 0.0:
				_state = PlantState.LOWERING
				_timer = 0.0
		PlantState.LOWERING:
			_timer += delta
			position.y = _hidden_y - rise_distance * (1.0 - clampf(_timer / rise_time, 0.0, 1.0))
			if _timer >= rise_time:
				position.y = _hidden_y
				_state = PlantState.WAITING
				_timer = hidden_time


func _player_is_near() -> bool:
	var p := get_player()
	if p == null:
		return false
	return absf(p.global_position.x - global_position.x) < near_distance


## Superball: points and gone.
func die_from_hit(_from_direction: float = 1.0) -> void:
	if is_dead:
		return
	_begin_death()
	_play_sfx("Enemykilled")
	award_score()
	hide()
	get_tree().create_timer(0.6).timeout.connect(queue_free)   # let the sound finish


# Old sensor-area signal names the pipe scene still connects to. Not needed any more.
func _on_left_area_area_entered(_area: Area2D) -> void:
	pass

func _on_right_area_area_entered(_area: Area2D) -> void:
	pass

func _on_top_area_area_entered(_area: Area2D) -> void:
	pass
