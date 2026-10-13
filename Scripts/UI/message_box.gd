extends CanvasLayer

class_name MessageBox
## A Super Mario World style message box. Pauses the game, shows the text, and waits for the
## player to press jump (or action / start) before closing.
##
## Use it from any script:
##     var box := MessageBox.open(get_tree(), "HELLO MARIO!")
##     await box.closed

signal closed

const FONT_PATH := "res://Assets/Fonts/super-mario-land-gb-doublecase.ttf"

@export var min_show_time: float = 0.6      ## can't be skipped before this many seconds

var _time: float = 0.0
var _was_paused: bool = false
var _was_down: bool = true     # a button already held when the box opens doesn't count


## Opens a message box on top of everything. accent = border colour.
static func open(tree: SceneTree, text: String, accent: Color = Color(1, 1, 1)) -> MessageBox:
	var box := MessageBox.new()
	box.layer = 50
	box.process_mode = Node.PROCESS_MODE_ALWAYS
	box._build(text, accent)
	tree.root.add_child(box)
	box._was_paused = tree.paused
	tree.paused = true
	return box


func _build(text: String, accent: Color) -> void:
	var view := Vector2(256, 144)
	var frame := ColorRect.new()
	frame.color = accent
	frame.position = Vector2(16, 20)
	frame.size = Vector2(view.x - 32, view.y - 40)
	add_child(frame)
	var inner := ColorRect.new()
	inner.color = Color(0.06, 0.06, 0.12)
	inner.position = Vector2(2, 2)
	inner.size = frame.size - Vector2(4, 4)
	frame.add_child(inner)
	var label := Label.new()
	label.name = "Text"
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.position = Vector2(6, 4)
	label.size = inner.size - Vector2(12, 16)
	label.add_theme_font_size_override("font_size", 7)
	label.add_theme_color_override("font_color", Color(1, 1, 1))
	if ResourceLoader.exists(FONT_PATH):
		label.add_theme_font_override("font", load(FONT_PATH))
	inner.add_child(label)
	var hint := Label.new()
	hint.text = "PRESS JUMP"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, inner.size.y - 12)
	hint.size = Vector2(inner.size.x, 10)
	hint.add_theme_font_size_override("font_size", 6)
	hint.add_theme_color_override("font_color", accent)
	if ResourceLoader.exists(FONT_PATH):
		hint.add_theme_font_override("font", load(FONT_PATH))
	inner.add_child(hint)


func get_text() -> String:
	var l := find_child("Text", true, false) as Label
	return l.text if l else ""


func _process(delta: float) -> void:
	_time += delta
	var down := Input.is_action_pressed("jump") or Input.is_action_pressed("action") or Input.is_action_pressed("Start")
	var pressed_now := down and not _was_down
	_was_down = down
	if _time >= min_show_time and pressed_now:
		close()


func close() -> void:
	if not is_inside_tree():
		return
	get_tree().paused = _was_paused
	closed.emit()
	queue_free()
