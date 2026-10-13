extends Enemy

class_name Suu
## Suu (World 3, Easton): a spider hanging from the ceiling. When Mario walks underneath it
## drops down on its thread, then climbs back up. Place it right under a ceiling.

@export var drop_distance: float = 64.0
@export var drop_speed: float = 120.0
@export var climb_speed: float = 40.0
@export var trigger_width: float = 16.0
@export var wait_at_bottom: float = 0.6

enum SuuState { WAITING, DROPPING, PAUSED, CLIMBING }

var _state: SuuState = SuuState.WAITING
var _top_y: float
var _pause_left: float = 0.0


func _on_ready() -> void:
	_top_y = global_position.y


func _configure_collision() -> void:
	collision_layer = Layers.bit(Layers.ENEMY)
	collision_mask = 0


func _alive_physics(delta: float) -> void:
	match _state:
		SuuState.WAITING:
			var p := get_player()
			if p and p.global_position.y > global_position.y and absf(p.global_position.x - global_position.x) < trigger_width:
				_state = SuuState.DROPPING
		SuuState.DROPPING:
			global_position.y += drop_speed * delta
			if global_position.y >= _top_y + drop_distance:
				_state = SuuState.PAUSED
				_pause_left = wait_at_bottom
		SuuState.PAUSED:
			_pause_left -= delta
			if _pause_left <= 0.0:
				_state = SuuState.CLIMBING
		SuuState.CLIMBING:
			global_position.y -= climb_speed * delta
			if global_position.y <= _top_y:
				global_position.y = _top_y
				_state = SuuState.WAITING
	queue_redraw()


## Draws the thread from the ceiling down to the spider.
func _draw() -> void:
	if global_position.y > _top_y + 1.0:
		draw_line(Vector2(0, _top_y - global_position.y - 4), Vector2(0, -4), Color(0.1, 0.1, 0.1), 1.0)
