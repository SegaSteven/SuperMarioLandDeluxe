extends Block

class_name ColorBlock
## A Super Mario World style switch block, in a colour (blue / red / pink).
##   Before that colour's switch is pressed: a dotted outline - Mario and enemies pass straight
##   through it.
##   After: solid. Its Kind decides what it is then:
##     SOLID    - a plain solid block (make bridges, stairs, walls, shortcuts, enemy blockers)
##     QUESTION - a ? block that gives that colour's power-up once, then turns empty
## Pick both in the Inspector. The art is drawn by this script (placeholder) in the colour from
## PowerUps.SWITCH_COLORS, so no images are needed until you make your own.

enum Kind { SOLID, QUESTION }

@export_enum("blue", "red", "pink") var color_name: String = "blue"
@export var kind: Kind = Kind.SOLID
@export var show_outline: bool = true        ## untick to make the block fully invisible until switched on

var is_on: bool = false
var is_empty: bool = false


func _ready() -> void:
	OverworldMan.unlocked.connect(_on_unlocked)
	_refresh()


func _on_unlocked(key: String) -> void:
	if key == PowerUps.switch_key(color_name):
		_refresh()


func _refresh() -> void:
	is_on = PowerUps.is_switch_on(color_name)
	# Off = no collision at all (pass through). On = solid like any other block.
	set_collision_layer_value(Layers.OBSTACLE, is_on)
	queue_redraw()


func bump(player_mode: PlayerUpdated.PlayerMode) -> void:
	if not is_on:
		return
	if kind == Kind.QUESTION and not is_empty:
		is_empty = true
		_spawn_power_up()
		queue_redraw()
	else:
		var sfx := get_node_or_null("HitHardBlock") as AudioStreamPlayer
		if sfx:
			sfx.play()
	super.bump(player_mode)


func _spawn_power_up() -> void:
	var id := PowerUps.power_up_for_switch(color_name)
	var path: String = PowerUps.get_data(id).get("item", "")
	if path == "":
		return
	var item = load(path).instantiate()
	item.global_position = global_position + Vector2(0, -4)
	get_tree().current_scene.add_child(item)


func _draw() -> void:
	var c: Color = PowerUps.SWITCH_COLORS.get(color_name, Color.WHITE)
	var r := Rect2(-4, -4, 8, 8)
	if not is_on:
		if not show_outline:
			return
		# dotted outline
		for i in range(0, 8, 2):
			draw_rect(Rect2(-4 + i, -4, 1, 1), c)
			draw_rect(Rect2(-4 + i, 3, 1, 1), c)
			draw_rect(Rect2(-4, -4 + i, 1, 1), c)
			draw_rect(Rect2(3, -4 + i, 1, 1), c)
		return
	var fill := c.darkened(0.5) if is_empty else c
	draw_rect(r, fill)
	draw_rect(r, Color(0.1, 0.08, 0.05), false, 1.0)
	if kind == Kind.QUESTION and not is_empty:
		# a tiny "?"
		var w := Color(1, 1, 1)
		draw_rect(Rect2(-1.5, -2.5, 3, 1), w)
		draw_rect(Rect2(0.5, -1.5, 1, 1), w)
		draw_rect(Rect2(-0.5, -0.5, 1, 1.5), w)
		draw_rect(Rect2(-0.5, 2, 1, 1), w)
