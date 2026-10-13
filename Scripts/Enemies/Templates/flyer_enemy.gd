extends Enemy

class_name FlyerEnemy
## A ready-made FLYING enemy. Ignores gravity. Pick a pattern in the Inspector:
##   STRAIGHT       - flies in a straight line (like a bullet / Bunbun without the spear)
##   WAVE           - flies sideways bobbing up and down (Bunbun-style)
##   PATROL_UP_DOWN - moves up and down between two heights, stays at the same x
##   PATROL_SIDE    - moves left and right between two points
##   CHASE          - slowly homes in on Mario
##   DIVE           - hovers, then swoops down when Mario walks underneath
## A stomp knocks flyers out of the sky (they tumble off-screen) - turn off
## can_be_stomped in the Inspector if it should hurt Mario instead.

enum Pattern { STRAIGHT, WAVE, PATROL_UP_DOWN, PATROL_SIDE, CHASE, DIVE }

@export_group("Flying")
@export var pattern: Pattern = Pattern.WAVE
@export var fly_speed: float = 40.0
@export var wave_height: float = 8.0          ## WAVE: how far up/down it bobs
@export var wave_speed: float = 4.0           ## WAVE: how fast it bobs
@export var patrol_distance: float = 32.0     ## PATROL_*: distance travelled each way
@export var chase_turn_speed: float = 2.0     ## CHASE: how quickly it steers towards Mario
@export var dive_trigger_width: float = 12.0  ## DIVE: how close (sideways) Mario must be
@export var dive_speed: float = 120.0         ## DIVE: swoop speed

@export_group("Animations")
@export var anim_fly: StringName = &"fly"

var _start: Vector2
var _time: float = 0.0
var _patrol_sign: int = 1
var _diving: bool = false


func _on_ready() -> void:
	_start = global_position
	_play_anim(anim_fly)


func _alive_physics(delta: float) -> void:
	_time += delta
	match pattern:
		Pattern.STRAIGHT:
			global_position.x += direction * fly_speed * delta
		Pattern.WAVE:
			global_position.x += direction * fly_speed * delta
			global_position.y = _start.y + sin(_time * wave_speed) * wave_height
		Pattern.PATROL_UP_DOWN:
			global_position.y += _patrol_sign * fly_speed * delta
			if absf(global_position.y - _start.y) >= patrol_distance:
				_patrol_sign = -_patrol_sign
		Pattern.PATROL_SIDE:
			global_position.x += _patrol_sign * fly_speed * delta
			if absf(global_position.x - _start.x) >= patrol_distance:
				_patrol_sign = -_patrol_sign
				_face(_patrol_sign)
		Pattern.CHASE:
			var p := get_player()
			if p:
				var want := global_position.direction_to(p.global_position) * fly_speed
				velocity = velocity.lerp(want, clampf(chase_turn_speed * delta, 0.0, 1.0))
				global_position += velocity * delta
				_face(1 if velocity.x > 0.0 else -1)
		Pattern.DIVE:
			var p2 := get_player()
			if not _diving and p2 and p2.global_position.y > global_position.y \
					and absf(p2.global_position.x - global_position.x) <= dive_trigger_width:
				_diving = true
			if _diving:
				global_position.y += dive_speed * delta


## No ground to be squashed against: a stomp knocks it out of the sky instead.
func stomp(_player: Node) -> void:
	die_from_hit(0.0)
