extends StaticBody2D

class_name ColorSwitch
## The big switch in a switch palace (Super Mario World). Jump on it and:
##   1. that colour's blocks turn on everywhere (saved),
##   2. that colour's power-up is unlocked (blue = speed shoes, red = Fire Flower, pink = bunny ears),
##   3. the music stops and a Super Mario World style message box pops up. It tells the player
##      the switch is active but NOT what it does - they have to find out (edit Message to change it).
##   4. when they close the box, the level is finished and the game returns to the map.
##      A switch palace can't be replayed once its switch is pressed (see MapNode.switch_color).
## Mario stands on it like a block; landing on top presses it (see Player_Updated.gd).

signal pressed(color_name: String)

@export_enum("blue", "red", "pink") var color_name: String = "blue"
@export var finish_level: bool = true
@export_file("*.tscn") var return_scene: String = "res://Scenes/WorldScenes/world_map.tscn"
@export var return_spawn: Vector2 = Vector2.ZERO
@export var delay_before_message: float = 1.0
@export var delay_before_leaving: float = 0.5
## %s is replaced with the colour name (BLUE / RED / PINK). Keep it vague - finding out is the fun.
@export_multiline var message: String = "YOU HAVE ACTIVATED THE %s SWITCH!\n\n%s BLOCKS ALL OVER THE KINGDOM HAVE CHANGED.\n\nWHAT COULD IT MEAN? GO AND FIND OUT!"

var is_pressed: bool = false


func _ready() -> void:
	collision_layer = Layers.bit(Layers.OBSTACLE)
	collision_mask = 0
	if PowerUps.is_switch_on(color_name):
		is_pressed = true      # already pressed on an earlier visit: stays flat
		_flatten()
	queue_redraw()


func _flatten() -> void:
	var cs := get_node_or_null("CollisionShape2D") as CollisionShape2D
	if cs:
		var flat := RectangleShape2D.new()
		flat.size = Vector2(16, 4)
		cs.set_deferred("shape", flat)
		cs.set_deferred("position", Vector2(0, 6))


func press(_by: Node = null) -> void:
	if is_pressed:
		return
	is_pressed = true
	_flatten()
	queue_redraw()
	var sfx := get_node_or_null("PressSound") as AudioStreamPlayer
	if sfx:
		sfx.play()
	PowerUps.press_switch(color_name)
	pressed.emit(color_name)
	var music := get_tree().current_scene.get_node_or_null("LevelMusic") as AudioStreamPlayer
	if music:
		music.stop()
	await get_tree().create_timer(delay_before_message, false).timeout
	if not is_inside_tree():
		return
	var box := MessageBox.open(get_tree(), message_text(), PowerUps.SWITCH_COLORS.get(color_name, Color.WHITE))
	await box.closed
	if not finish_level or not is_inside_tree():
		return
	await get_tree().create_timer(delay_before_leaving, false).timeout
	if not is_inside_tree():
		return
	GameManager.win()
	GameManager.travel_to(return_scene, return_spawn, {"pattern": "squares", "speed": 4})


func message_text() -> String:
	var up := color_name.to_upper()
	return message.replace("%s", up)


func _draw() -> void:
	var c: Color = PowerUps.SWITCH_COLORS.get(color_name, Color.WHITE)
	var ink := Color(0.1, 0.08, 0.05)
	if is_pressed:
		draw_rect(Rect2(-8, 4, 16, 4), c.darkened(0.3))
		draw_rect(Rect2(-8, 4, 16, 4), ink, false, 1.0)
		return
	draw_rect(Rect2(-8, -8, 16, 16), c)
	draw_rect(Rect2(-8, -8, 16, 16), ink, false, 1.0)
	# a white "!"
	draw_rect(Rect2(-1, -5, 2, 6), Color.WHITE)
	draw_rect(Rect2(-1, 3, 2, 2), Color.WHITE)
