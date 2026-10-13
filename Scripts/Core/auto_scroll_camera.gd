extends Camera2D

class_name AutoScrollCamera
## Camera for auto-scrolling levels (submarine / plane / any forced-scroll stage).
## Moves right on its own at `scroll_speed`, ignoring Mario. Put it in place of the normal
## level camera (which follows Mario).
##
## Speed changes: add entries to "Speed Zones" - each is Vector2(x_position, new_speed).
## When the middle of the screen passes x_position, the speed changes. Speed 0 = stop there.
## The camera stops for good at the camera's Limit Right (set it in the Inspector).

signal reached_end

@export var scroll_speed: float = 24.0        ## pixels per second (Marine Pop is slow and steady)
@export var start_delay: float = 1.0          ## wait before it starts moving
@export var speed_zones: Array[Vector2] = []  ## Vector2(x, speed) - see above
@export var vertical_speed: float = 0.0       ## for levels that also scroll up or down

var scrolling: bool = false
var _finished: bool = false
var _zone_index: int = 0


func _ready() -> void:
	make_current()
	position_smoothing_enabled = false
	drag_horizontal_enabled = false
	drag_vertical_enabled = false
	speed_zones.sort_custom(func(a, b): return a.x < b.x)
	if start_delay > 0.0:
		await get_tree().create_timer(start_delay, false).timeout
	scrolling = true


func _physics_process(delta: float) -> void:
	if not scrolling or _finished:
		return

	var centre_x := get_screen_center_position().x
	while _zone_index < speed_zones.size() and centre_x >= speed_zones[_zone_index].x:
		scroll_speed = speed_zones[_zone_index].y
		_zone_index += 1

	var half_width := get_viewport_rect().size.x * 0.5 / zoom.x
	if centre_x + half_width >= limit_right:
		_finished = true
		reached_end.emit()
		return

	global_position.x += scroll_speed * delta
	global_position.y += vertical_speed * delta


## Pause / resume scrolling from other scripts (e.g. a mini-boss arena).
func stop_scrolling() -> void:
	scrolling = false


func resume_scrolling() -> void:
	scrolling = true
