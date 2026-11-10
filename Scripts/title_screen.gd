extends Node
## Title screen. Left / Right moves the mushroom between START and OPTIONS; Start or Jump picks.
## The one the mushroom is on is white, the other is medium grey.
##   START    flashes, the coin sound (with reverb), half a second, then the squares wipe
##   OPTIONS  the Options box (volume, display mode, key binding) - see Scripts/UI/options_menu.gd

@onready var ui_data = preload("res://Scripts/ui.gd")
@onready var ScoreCard = $SCORE                 # the START text
@onready var options_label: Label = get_node_or_null("OPTIONS")
@onready var cursor: Sprite2D = $Shroom
@export var next_scene = "res://Scenes/LoadRoom/load_room.tscn"   ## the load room (save files)
## Sound when START is picked, then a short wait before the squares wipe.
@export var start_sound: AudioStream = preload("res://Assets/SFX/coin_reverb.wav")
@export var wait_before_transition: float = 0.5
@export var stop_music_on_start: bool = true
@export var transition: Dictionary = {"pattern": "squares", "speed": 4}
@export_group("Menu")
@export var selected_color: Color = Color(1, 1, 1)
@export var unselected_color: Color = Color(0.55, 0.55, 0.55)   ## medium grey
## Once START is picked it flashes: shown this long...
@export var flash_on_time: float = 0.25
## ...then hidden this long.
@export var flash_off_time: float = 0.125
@export var cursor_gap: float = 6.0             ## space between the mushroom and the text
@export var move_sound: AudioStream             ## optional blip when the mushroom moves
@export_group("")
@onready var title_logo: Sprite2D = $Background/TitleLogo
@onready var deluxe: AnimatedSprite2D = $Background/Deluxe

var title_done = false
var selected: int = 0          # 0 = START, 1 = OPTIONS
var _starting: bool = false
var _options_open: bool = false
var _flash_t: float = 0.0
var _input_cooldown: float = 0.0


func _ready():
	$TitleScreen.play()
	# each label gets its own settings so they can be different colours
	for l in [ScoreCard, options_label]:
		if l and l.label_settings:
			l.label_settings = l.label_settings.duplicate()
	_place_cursor()


func set_score(points: int):
	ScoreCard.text = "%d" % points


func _process(delta: float) -> void:
	_flash(delta)
	if _starting or _options_open:
		return
	if _input_cooldown > 0.0:
		_input_cooldown -= delta
		return
	if options_label and (Input.is_action_just_pressed("left") or Input.is_action_just_pressed("right")):
		selected = 1 - selected
		_place_cursor()
		_play(move_sound)
	elif Input.is_action_just_pressed("Start") or Input.is_action_just_pressed("jump"):
		if selected == 0:
			_start_game()
		else:
			_open_options()


## START only flashes once it's been picked.
func _flash(delta: float) -> void:
	if not _starting:
		ScoreCard.visible = true
		return
	_flash_t += delta
	if _flash_t >= flash_on_time + flash_off_time:
		_flash_t = 0.0
	ScoreCard.visible = _flash_t < flash_on_time


func _place_cursor() -> void:
	var lbl: Label = ScoreCard if selected == 0 else options_label
	for l in [ScoreCard, options_label]:
		if l and l.label_settings:
			l.label_settings.font_color = selected_color if l == lbl else unselected_color
	if lbl == null or cursor == null:
		return
	var w := cursor.texture.get_width() if cursor.texture else 8
	cursor.position = Vector2(lbl.position.x - cursor_gap - w * 0.5 + 2.0, cursor.position.y)


## START picked: sound, half a second, then the squares wipe into the load room.
func _start_game() -> void:
	_starting = true
	_flash_t = 0.0
	if stop_music_on_start:
		$TitleScreen.stop()
	if start_sound:
		# played from the root so its echo isn't cut off when the scene changes
		var p := AudioStreamPlayer.new()
		p.stream = start_sound
		get_tree().root.add_child(p)
		p.play()
		p.finished.connect(p.queue_free)
	await get_tree().create_timer(wait_before_transition).timeout
	SceneManager.change_scene(next_scene, transition)


func _open_options() -> void:
	_options_open = true
	var box := OptionsMenu.open(get_tree(), $TitleScreen)
	await box.closed
	_options_open = false
	_input_cooldown = 0.2          # the button that closed the box doesn't also pick something


func _play(stream: AudioStream) -> void:
	if stream == null:
		return
	var p := AudioStreamPlayer.new()
	p.stream = stream
	add_child(p)
	p.play()
	p.finished.connect(p.queue_free)
