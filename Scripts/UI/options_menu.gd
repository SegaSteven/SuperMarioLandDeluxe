extends CanvasLayer

class_name OptionsMenu
## The Options box (title screen) and the Paused box (in levels) - the same menu.
## Black box, red and white trim, white text. It grows out of a small black square in the
## middle of the screen in 3 steps when it opens, and shrinks back the same way when it closes.
##   Game Volume    Left / Right: bars for the whole game's volume
##   Display Mode   Left / Right: Fullscreen / Windowed (the white one is the one in use)
##   Key Binding    Left / Right: Default / Custom. Choosing Custom opens the key box.
##   then the bottom items:
##     title screen   Back                         (Jump / Start - or Action - closes it)
##     paused         Exit Level, Exit to Title    (press Pause again to carry on playing)
## Up / Down moves between them; the mushroom shows where you are.
## Settings are saved straight away (see Scripts/Core/game_settings.gd).
##
## From code:
##   var box := OptionsMenu.open(get_tree(), $TitleMusic)          # Options, with Back
##   var box := OptionsMenu.open_paused(get_tree())                # the Paused box
##   box.chosen.connect(func(item): ...)                           # "Exit Level" / "Exit to Title"
##   await box.closed

signal closed
## A bottom item other than Back was picked ("Exit Level", "Exit to Title").
signal chosen(item: String)

const COL_TEXT := Color(1, 1, 1)
const COL_OFF := Color(0.55, 0.55, 0.55)     # the choice that isn't selected
const COL_TRIM_RED := Color(0.85, 0.1, 0.1)
const COL_TRIM_WHITE := Color(1, 1, 1)
const CURSOR_TEX := "res://Assets/Title Screen/Sprites/Shroom.png"
## The heart tiles from the old pause bar (TileSets/main.tres, source 1, tile 1,2).
const HEART_TILESET := "res://TileSets/main.tres"
const HEART_SOURCE := 1
const HEART_TILE := Vector2i(1, 2)

const BOX_WIDTH := 200.0
const ROW_GAP := 24.0        # space between Game Volume / Display Mode / Key Binding
const ITEM_GAP := 12.0       # space between the bottom items

enum Row { VOLUME, DISPLAY, KEYS }

## Title text at the top of the box.
var title: String = "Options"
## The rows at the bottom. "Back" closes the box; anything else emits chosen(item).
var bottom_items: Array[String] = ["Back"]
## Draw the hearts either side of the title (the Paused box).
var hearts: bool = false
## Buttons that close the box straight away.
var close_actions: Array[String] = ["action"]
## How much quieter the music goes while the box is open (dB).
var music_duck_db: float = -12.0
## The opening / closing animation: number of steps and seconds per step.
var grow_steps: int = 3
var grow_step_time: float = 0.05
var start_size: Vector2 = Vector2(12, 12)

var row: int = 0
var _music: AudioStreamPlayer
var _music_db: float = 0.0
var _rect: Rect2
var _box: Control
var _grow: ColorRect
var _cursor: TextureRect
var _bars: Array[ColorRect] = []
var _choices: Dictionary = {}          # row -> [left Label, right Label]
var _row_y: Array[float] = []
var _keybox: KeyBindBox
var _ready_for_input: bool = false
var _closing: bool = false


## Opens the Options box over the current scene. music = the music to turn down while it's open.
static func open(tree: SceneTree, music: AudioStreamPlayer = null) -> OptionsMenu:
	var m := OptionsMenu.new()
	m._music = music
	tree.root.add_child(m)
	return m


## Opens the Paused box (in a level). The level pauses and resumes the game itself.
static func open_paused(tree: SceneTree) -> OptionsMenu:
	var m := OptionsMenu.new()
	m.title = "Paused"
	m.hearts = true
	m.bottom_items = ["Exit Level", "Exit to Title"]
	m.close_actions = ["Pause"]
	tree.root.add_child(m)
	return m


func row_count() -> int:
	return 3 + bottom_items.size()


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _music:
		_music_db = _music.volume_db
		_music.volume_db = _music_db + music_duck_db
	var h := 98.0 + (bottom_items.size() - 1) * ITEM_GAP + 18.0
	var vp := Vector2(256, 144)
	_rect = Rect2(((vp - Vector2(BOX_WIDTH, h)) * 0.5).round(), Vector2(BOX_WIDTH, h))
	_build()
	_refresh()
	await _animate(true)
	_ready_for_input = true


## A black box with a red and white border, inside `parent`, covering `r`.
static func make_box(parent: Node, r: Rect2) -> Control:
	var root := Control.new()
	root.position = r.position
	root.size = r.size
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(root)
	for layer_def in [[0, COL_TRIM_RED], [2, COL_TRIM_WHITE], [3, Color(0, 0, 0)]]:
		var c := ColorRect.new()
		c.color = layer_def[1]
		c.position = Vector2(layer_def[0], layer_def[0])
		c.size = r.size - Vector2(layer_def[0], layer_def[0]) * 2
		c.mouse_filter = Control.MOUSE_FILTER_IGNORE
		root.add_child(c)
	return root


static func text(parent: Node, s: String, pos: Vector2, col: Color = COL_TEXT, width: float = 0.0, centre: bool = false) -> Label:
	var l := SaveUfo.make_label(col)
	l.text = s
	l.position = pos
	if centre:
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		l.size = Vector2(width, 9)
	parent.add_child(l)
	return l


## The heart picture from the old pause bar (null if the tileset isn't there).
static func heart_texture() -> Texture2D:
	if not ResourceLoader.exists(HEART_TILESET):
		return null
	var ts := load(HEART_TILESET) as TileSet
	if ts == null or not ts.has_source(HEART_SOURCE):
		return null
	var src := ts.get_source(HEART_SOURCE) as TileSetAtlasSource
	if src == null or not src.has_tile(HEART_TILE):
		return null
	var at := AtlasTexture.new()
	at.atlas = src.texture
	at.region = src.get_tile_texture_region(HEART_TILE)
	return at


## Grows out of (or shrinks back into) a small black square in the middle of the screen.
func _animate(opening: bool) -> void:
	if _grow == null:
		_grow = ColorRect.new()
		_grow.color = Color(0, 0, 0)
		_grow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		add_child(_grow)
	_box.visible = false
	_grow.visible = true
	var centre := _rect.get_center()
	var steps := maxi(grow_steps, 1)
	for i in steps:
		var k := float(i) / steps if opening else float(steps - i) / steps
		var sz := start_size.lerp(_rect.size, k).round()
		_grow.position = (centre - sz * 0.5).round()
		_grow.size = sz
		await get_tree().create_timer(grow_step_time, true, false, true).timeout
	_grow.visible = false
	_box.visible = opening


func _build() -> void:
	_box = make_box(self, _rect)
	var w := _rect.size.x
	var t := text(_box, title, Vector2(0, 6), COL_TEXT, w, true)
	if hearts:
		var tex := heart_texture()
		if tex:
			var half := t.label_settings.font.get_string_size(title, HORIZONTAL_ALIGNMENT_LEFT, -1, 7).x * 0.5
			for side in [-1, 1]:
				var hr := TextureRect.new()
				hr.texture = tex
				hr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				hr.position = Vector2(w * 0.5 + side * (half + 8) - 4, 5).round()
				_box.add_child(hr)
	var line := ColorRect.new()
	line.color = COL_TRIM_RED
	line.position = Vector2(12, 17)
	line.size = Vector2(w - 24, 1)
	_box.add_child(line)

	_row_y = [24.0, 24.0 + ROW_GAP, 24.0 + ROW_GAP * 2]
	text(_box, "Game Volume", Vector2(22, _row_y[Row.VOLUME]))
	for i in GameSettings.MAX_VOLUME:
		var b := ColorRect.new()
		b.position = Vector2(32 + i * 12, _row_y[Row.VOLUME] + 11)
		b.size = Vector2(8, 6)
		_box.add_child(b)
		_bars.append(b)
	text(_box, "Display Mode", Vector2(22, _row_y[Row.DISPLAY]))
	_choices[Row.DISPLAY] = [text(_box, "Fullscreen", Vector2(32, _row_y[Row.DISPLAY] + 11)),
		text(_box, "Windowed", Vector2(124, _row_y[Row.DISPLAY] + 11))]
	text(_box, "Key Binding", Vector2(22, _row_y[Row.KEYS]))
	_choices[Row.KEYS] = [text(_box, "Default", Vector2(32, _row_y[Row.KEYS] + 11)),
		text(_box, "Custom", Vector2(124, _row_y[Row.KEYS] + 11))]
	var y := 24.0 + ROW_GAP * 3 + 2.0
	for item in bottom_items:
		text(_box, item, Vector2(22, y))
		_row_y.append(y)
		y += ITEM_GAP

	_cursor = TextureRect.new()
	if ResourceLoader.exists(CURSOR_TEX):
		_cursor.texture = load(CURSOR_TEX)
	_cursor.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_box.add_child(_cursor)


func _refresh() -> void:
	for i in _bars.size():
		_bars[i].color = COL_TEXT if i < GameSettings.volume else Color(0.25, 0.25, 0.25)
	_set_choice(Row.DISPLAY, 0 if GameSettings.fullscreen else 1)
	_set_choice(Row.KEYS, 1 if GameSettings.custom_keys else 0)
	if _cursor.texture:
		var ts := _cursor.texture.get_size()
		_cursor.position = Vector2(20 - ts.x - 2, _row_y[row] + 4 - ts.y * 0.5).round()


func _set_choice(r: int, selected: int) -> void:
	var pair: Array = _choices[r]
	for i in 2:
		(pair[i] as Label).label_settings.font_color = COL_TEXT if i == selected else COL_OFF


func _input(event: InputEvent) -> void:
	if _closing:
		get_viewport().set_input_as_handled()
		return
	if not _ready_for_input or _keybox != null:
		return
	var handled := true
	if close_actions.any(func(a): return event.is_action_pressed(a)):
		close()
	elif event.is_action_pressed("Up"):
		row = wrapi(row - 1, 0, row_count())
	elif event.is_action_pressed("down"):
		row = wrapi(row + 1, 0, row_count())
	elif event.is_action_pressed("left", true):
		_change(-1)
	elif event.is_action_pressed("right", true):
		_change(1)
	elif event.is_action_pressed("jump") or event.is_action_pressed("Start"):
		_confirm()
	else:
		handled = false
	if handled:
		get_viewport().set_input_as_handled()
		if is_inside_tree() and not _closing:
			_refresh()


func _change(step: int) -> void:
	match row:
		Row.VOLUME:
			GameSettings.set_volume(GameSettings.volume + step)
		Row.DISPLAY:
			GameSettings.set_fullscreen(step < 0)          # left = Fullscreen, right = Windowed
		Row.KEYS:
			if step > 0:
				if not GameSettings.custom_keys:
					GameSettings.set_custom_keys(true)
				_open_keys()
			else:
				GameSettings.set_custom_keys(false)


func _confirm() -> void:
	if row == Row.KEYS:
		if GameSettings.custom_keys:
			_open_keys()
		return
	if row < 3:
		return
	var item := bottom_items[row - 3]
	if item == "Back":
		close()
	else:
		chosen.emit(item)


func _open_keys() -> void:
	if _keybox != null:
		return
	_keybox = KeyBindBox.new()
	_cursor.visible = false
	add_child(_keybox)
	await _keybox.closed
	_keybox = null
	_cursor.visible = true
	_refresh()


## Shrinks the box away, then emits closed.
func close() -> void:
	if _closing:
		return
	_closing = true
	if _music and is_instance_valid(_music):
		_music.volume_db = _music_db
	await _animate(false)
	closed.emit()
	queue_free()
