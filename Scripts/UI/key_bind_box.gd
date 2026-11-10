extends Control

class_name KeyBindBox
## The key binding box (Options > Key Binding > Custom). Shows each action and its key.
## Up / Down to pick one, Jump / Start to change it - then press the new key (Esc = keep the
## old one). "Done" at the bottom closes the box. Saved straight away.

signal closed

const BOX := Rect2(34, 22, 188, 100)

var row: int = 0
var _waiting: bool = false
var _names: Array[Label] = []
var _keys: Array[Label] = []
var _done: Label
var _cursor: TextureRect
var _ready_for_input: bool = false


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var box := OptionsMenu.make_box(self, BOX)
	OptionsMenu.text(box, "Key Binding", Vector2(0, 5), OptionsMenu.COL_TEXT, BOX.size.x, true)
	var y := 18
	for a in GameSettings.BINDABLE:
		_names.append(OptionsMenu.text(box, GameSettings.LABELS[a].capitalize(), Vector2(22, y)))
		_keys.append(OptionsMenu.text(box, "", Vector2(86, y)))
		y += 11
	_done = OptionsMenu.text(box, "Done", Vector2(22, y + 3))
	_cursor = TextureRect.new()
	if ResourceLoader.exists(OptionsMenu.CURSOR_TEX):
		_cursor.texture = load(OptionsMenu.CURSOR_TEX)
	box.add_child(_cursor)
	_refresh()
	await get_tree().create_timer(0.15, true, false, true).timeout
	_ready_for_input = true


func _refresh() -> void:
	for i in GameSettings.BINDABLE.size():
		var a: String = GameSettings.BINDABLE[i]
		_keys[i].text = "Press a key" if (_waiting and i == row) else GameSettings.key_name(a)
		_keys[i].label_settings.font_color = OptionsMenu.COL_TEXT if i == row else OptionsMenu.COL_OFF
	var y: float = (_names[row].position.y if row < _names.size() else _done.position.y)
	if _cursor.texture:
		var ts := _cursor.texture.get_size()
		_cursor.position = Vector2(20 - ts.x - 2, y + 4 - ts.y * 0.5).round()


func _input(event: InputEvent) -> void:
	if not _ready_for_input:
		return
	if _waiting:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.physical_keycode != KEY_ESCAPE:
				var e := InputEventKey.new()
				e.physical_keycode = event.physical_keycode if event.physical_keycode != 0 else event.keycode
				GameSettings.bind(GameSettings.BINDABLE[row], e)
			_waiting = false
			get_viewport().set_input_as_handled()
			_refresh()
		return
	var count := GameSettings.BINDABLE.size() + 1      # + Done
	if event.is_action_pressed("Up"):
		row = wrapi(row - 1, 0, count)
	elif event.is_action_pressed("down"):
		row = wrapi(row + 1, 0, count)
	elif event.is_action_pressed("jump") or event.is_action_pressed("Start"):
		if row == GameSettings.BINDABLE.size():
			get_viewport().set_input_as_handled()
			closed.emit()
			queue_free()
			return
		_waiting = true
	else:
		return
	get_viewport().set_input_as_handled()
	_refresh()
