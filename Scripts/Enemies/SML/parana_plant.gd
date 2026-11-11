extends Enemy

class_name PranahaPlant
## Piranha plant that lives inside a pipe. Pops up, waits, goes back down.
## It won't come out while Mario is inside its WATCH AREA (like the Mario games): a box around
## its pipe - Watch Width wide, from Watch Above pixels over the pipe's top down to Watch Below
## pixels under it - so standing next to the pipe, on it, or jumping just over it keeps it in.
## Tick Show Watch Area to see the box in the game while testing.
## The wait before it pops out is random each time, between Wait Min and Wait Max.
## Can't be stomped; a superball removes it.

@export var start_time: float = 1.0               ## minimum wait before the first pop-up
@export var paranha_plant_time: float = 3.0       ## seconds it stays up
@export var rise_distance: float = 16.0
@export var rise_time: float = 1.0                ## seconds to come out / go back in (smaller = faster)

@export_group("Random wait")
@export var wait_min: float = 1.5                 ## shortest wait inside the pipe (seconds)
@export var wait_max: float = 4.0                 ## longest wait inside the pipe (seconds)

@export_group("Watching for Mario")
@export var watch_width: float = 48.0             ## box width, centred on the pipe (pipe 16 + 16 each side)
@export var watch_above: float = 40.0             ## box reaches this far above the pipe's top
@export var watch_below: float = 32.0             ## and this far below it (down to the ground)
@export var mouth_offset: float = 4.0             ## the pipe's top, this far above the pipe's origin
@export var show_watch_area: bool = false:        ## draw the box in the game (testing)
	set(v):
		show_watch_area = v
		queue_redraw()
@export_group("")

## Old setting, kept so existing scenes load: the wait now comes from Wait Min / Wait Max.
@export var hidden_time: float = 3.0

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
	_rng.randomize()
	_timer = start_time + _random_wait()


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
				_timer = _random_wait()


func _random_wait() -> float:
	return _rng.randf_range(minf(wait_min, wait_max), maxf(wait_min, wait_max))


## True while Mario is inside the watch area - the plant stays in.
func _player_is_near() -> bool:
	var p := get_player()
	if p == null:
		return false
	return watch_rect().has_point(p.global_position)


## The top of the pipe the plant comes out of.
func mouth_position() -> Vector2:
	var pipe := get_parent() as Node2D
	var pipe_y := pipe.global_position.y if pipe else global_position.y
	return Vector2(global_position.x, pipe_y - mouth_offset)


## The watch area in the level.
func watch_rect() -> Rect2:
	var mo := mouth_position()
	return Rect2(mo.x - watch_width * 0.5, mo.y - watch_above, watch_width, watch_above + watch_below)


func _process(_delta: float) -> void:
	if show_watch_area:
		queue_redraw()


func _draw() -> void:
	if not show_watch_area:
		return
	var r := watch_rect()
	draw_rect(Rect2(r.position - global_position, r.size), Color(1, 1, 1, 0.9), false, 1.0)


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
