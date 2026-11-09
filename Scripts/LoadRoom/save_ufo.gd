extends Node2D

class_name SaveUfo
## One save file in the load room. Mario climbs its ladder to get in and play that file.
##
## Above it: how far the file has got -
##   nothing          = empty file (never played)
##   a number 0-12    = main levels beaten
##   a star + 1-5     = Star Road levels beaten (star 5 = the whole game done)
## and up to 3 tiny blocks, one per switch palace pressed (blue, red, pink), nothing if not.
##
## ART: add a Sprite2D or AnimatedSprite2D child called "Body" with your UFO art and the
## placeholder drawing switches off. Star Texture replaces the drawn star.

signal boarded(slot: int)

@export_range(1, 3) var slot: int = 1
@export var info_offset: Vector2 = Vector2(0, -22)      ## where the number / blocks sit
@export var star_texture: Texture2D
@export var block_size: int = 2                          ## the switch blocks are 2x2 px
@export var block_gap: int = 2
@export var number_color: Color = Color(1, 1, 1)
@export var bob_height: float = 1.5                      ## gentle hover
@export var bob_speed: float = 2.0
@export var board_sound: AudioStream
@export var liftoff_time: float = 1.0

var summary: Dictionary = {}
var busy: bool = false              # boarding / exploding / arriving
var exploded: bool = false
var _t: float = 0.0
var _bob: float = 0.0
var _label: Label

const FONT_PATH := "res://Assets/Fonts/super-mario-land-gb-doublecase.ttf"


func _ready() -> void:
	add_to_group("save_ufos")
	_label = make_label(number_color)
	_label.name = "InfoLabel"
	add_child(_label)
	if board_sound == null and ResourceLoader.exists("res://Assets/SFX/doorway.wav"):
		board_sound = load("res://Assets/SFX/doorway.wav")
	refresh()


func _process(delta: float) -> void:
	_t += delta
	_bob = sin(_t * bob_speed) * bob_height if not busy else 0.0
	var body := get_node_or_null("Body") as Node2D
	if body:
		body.position.y = _bob
	queue_redraw()


## Re-reads the save file and redraws the info.
func refresh() -> void:
	summary = OverworldMan.slot_summary(slot)
	if _label == null:
		return
	if not summary.exists:
		_label.text = ""
	else:
		var star: bool = summary.star_levels > 0
		_label.text = str(summary.star_levels) if star else str(summary.levels)
		var w := pixel_font().get_string_size(_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x
		var star_w := 9.0 if star else 0.0
		_label.position = Vector2(info_offset.x - (w + star_w) * 0.5 + star_w, info_offset.y - 8)
	queue_redraw()


func can_board() -> bool:
	return not busy and not exploded


## Mario climbs in, the UFO lifts off, then the load room starts this file.
func board(player: PlayerUpdated) -> void:
	busy = true
	player.state_machine.transition_to(&"Hidden")
	_play(board_sound)
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_property(self, "position:y", position.y - 4.0, 0.25)
	tw.tween_property(self, "position:y", -60.0, liftoff_time).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func(): boarded.emit(slot))


## Blown up by the SAM cannon. Hides the UFO; arrive_new() brings in an empty one.
func blow_up() -> void:
	exploded = true
	visible = false


## A fresh UFO drops in from above the screen (empty file).
func arrive_new(time: float = 1.0) -> void:
	busy = true
	var home := position
	position.y = -40.0
	exploded = false
	visible = true
	refresh()
	var tw := create_tween()
	tw.tween_property(self, "position", home, time).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func(): busy = false)
	await tw.finished


## Where the cannon aims (the middle of the UFO body).
func target_position() -> Vector2:
	return global_position + Vector2(0, _bob)


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)


static func pixel_font() -> Font:
	if ResourceLoader.exists(FONT_PATH):
		return load(FONT_PATH)
	return ThemeDB.fallback_font


## A Label in the game's pixel font (same settings as the map UI: size 7).
static func make_label(color: Color = Color.WHITE, size: int = 7) -> Label:
	var l := Label.new()
	var ls := LabelSettings.new()
	ls.font = pixel_font()
	ls.font_size = size
	ls.font_color = color
	l.label_settings = ls
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _draw() -> void:
	# --- the UFO itself (placeholder, only if there's no "Body" child)
	if get_node_or_null("Body") == null:
		var y := _bob
		draw_colored_polygon(PackedVector2Array([Vector2(-6, y - 2), Vector2(-4, y - 7), Vector2(4, y - 7), Vector2(6, y - 2)]), Color(0.55, 0.85, 1.0, 0.9))
		draw_colored_polygon(PackedVector2Array([Vector2(-14, y), Vector2(-8, y - 3), Vector2(8, y - 3), Vector2(14, y), Vector2(8, y + 4), Vector2(-8, y + 4)]), Color(0.7, 0.7, 0.75))
		for i in 4:
			var on := int(_t * 6.0 + i) % 2 == 0
			draw_rect(Rect2(Vector2(-9 + i * 5, y), Vector2(2, 2)), Color(1, 0.9, 0.2) if on else Color(0.5, 0.4, 0.1))
		draw_rect(Rect2(Vector2(-3, y + 4), Vector2(6, 2)), Color(0.3, 0.3, 0.35))   # hatch for the ladder

	# --- the file info
	if summary.is_empty() or not summary.exists:
		return
	# The number is the InfoLabel child; the star goes just left of it
	if summary.star_levels > 0:
		var x0 := _label.position.x - 9.0
		if star_texture:
			draw_texture(star_texture, Vector2(x0, info_offset.y - 7))
		else:
			_draw_star(Vector2(x0 + 3.5, info_offset.y - 3.5), 4.0, Color(1, 0.9, 0.2))

	# Switch blocks: 3 places, a block only where that switch is pressed
	var n := OverworldMan.SAVE_SWITCHES.size()
	var total := n * block_size + (n - 1) * block_gap
	var bx := info_offset.x - total * 0.5
	for i in n:
		var c: String = OverworldMan.SAVE_SWITCHES[i]
		if summary.switches.get(c, false):
			draw_rect(Rect2(Vector2(bx + i * (block_size + block_gap), info_offset.y + 3), Vector2(block_size, block_size)),
				PowerUps.SWITCH_COLORS.get(c, Color.WHITE))


func _draw_star(c: Vector2, r: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 10:
		var a := -PI / 2.0 + i * PI / 5.0
		var rr := r if i % 2 == 0 else r * 0.45
		pts.append(c + Vector2(cos(a), sin(a)) * rr)
	draw_colored_polygon(pts, col)
