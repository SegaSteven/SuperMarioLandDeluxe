extends LevelData

class_name BasicLevel
## THE level script - every level and underground room uses this one (1-1, 1-2, 1-3, their
## underground rooms, the switch palaces...). There's no per-level code any more: pipes, vines
## and exit doors carry their own destinations (Destination Scene / Destination Spawn), so a
## new level just needs this script on its root node.
##
## What it does when the level starts:
##   - puts Mario at the checkpoint or spawn point, snaps the camera to him
##   - Play Start Flash on: the quick white flash, the UI appears after it and the level music
##     starts (overground levels). Off: no flash, the music is left alone (underground rooms,
##     whose LevelMusic plays by itself)
##   - stops the level music during the star and starts it again after
##   - Pause opens the Paused box (see LevelData.swap_pause_state)

## The flash at the start, then the UI and music. Untick for underground rooms.
@export var play_start_flash: bool = true
## Seconds before the UI shows and the music starts (with the flash).
@export var start_delay: float = 0.2

@export_group("Star Coins")
## Drag the level's star coins in here - the box decides which is the 1st, 2nd and 3rd coin
## (that's the order the map shows them in). Coins in an underground room go in that room's
## boxes instead.
@export var star_coin_1: StarCoin
@export var star_coin_2: StarCoin
@export var star_coin_3: StarCoin
## Warn (in the Output panel when the level runs) if a box is empty or a coin is in two boxes.
## Untick for rooms without coins, or for a level whose missing coins are in its underground rooms.
@export var check_star_coins: bool = true
@export_group("")

@onready var flash: CanvasItem = get_node_or_null("Camera2D/Flash")
@onready var pause_sfx: AudioStreamPlayer = get_node_or_null("Pause/PauseSFX")
@onready var camera: Camera2D = get_node_or_null("Camera2D")


func _ready() -> void:
	if pause_label:
		pause_label.hide()
	_number_star_coins()
	GameManager.start_level()
	GameManager.respawn_player()
	_start_pipe_exit()
	if camera:
		camera.reset_smoothing()
	if player:
		player.super_mode_play.connect(func(): if level_music: level_music.stop())
		player.super_mode_stop.connect(func(): if level_music: level_music.play())
	if ui and ui.has_method("_process"):
		ui._process(0)                    # show lives / coins / score straight away

	if play_start_flash:
		if ui:
			ui.hide()
		if level_music:
			level_music.stop()
		if flash:
			_flash_to_screen()
			flash.visible = true
			var tw := create_tween()
			tw.tween_property(flash, "modulate:a", 1.0, start_delay)
			tw.tween_property(flash, "modulate:a", 0.0, 0.1)
		await get_tree().create_timer(start_delay).timeout
		if ui:
			ui.show()
		if level_music and level_music.stream:
			level_music.play()
	level_start.emit()


## Gives each coin in the Star Coin boxes its number, and checks they're all there and different.
func _number_star_coins() -> void:
	var slots := [star_coin_1, star_coin_2, star_coin_3]
	var problems: Array[String] = []
	for i in 3:
		var c: StarCoin = slots[i]
		if c == null:
			problems.append("Star Coin %d box is empty" % (i + 1))
			continue
		if slots.find(c) != i:
			problems.append("%s is in Star Coin %d and %d" % [c.name, slots.find(c) + 1, i + 1])
			continue
		c.coin_number = i + 1
	# Coins in the level that aren't in a box
	for c in find_children("*", "StarCoin", true, false):
		if not slots.has(c):
			problems.append("%s isn't in a Star Coin box (using its Coin Number %d)" % [c.name, c.coin_number])
	if check_star_coins and not problems.is_empty():
		push_warning("%s star coins: %s" % [name, ", ".join(problems)])


## The Flash sits on the camera, so when the camera is held at the edge of the level (the start)
## it didn't line up with the screen. Put it on its own screen layer, covering everything.
func _flash_to_screen() -> void:
	if not (flash is Control) or flash.get_parent() is CanvasLayer:
		return
	var layer := CanvasLayer.new()
	layer.name = "FlashLayer"
	layer.layer = 90
	add_child(layer)
	flash.reparent(layer, false)
	var c := flash as Control
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.offset_left = 0
	c.offset_top = 0
	c.offset_right = 0
	c.offset_bottom = 0
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE


## Arrived through a pipe: Mario slides out of the pipe here once the screen fade finishes.
func _start_pipe_exit() -> void:
	var how := GameManager.pipe_exit
	GameManager.pipe_exit = ""
	if how == "" or player == null or GameManager.has_checkpoint_in(scene_file_path):
		return
	var dirs := {"up": Vector2.UP, "down": Vector2.DOWN, "left": Vector2.LEFT, "right": Vector2.RIGHT, "auto": Vector2.UP}
	if not dirs.has(how) or player.state_machine == null:
		return
	player.state_machine.transition_to(&"PipeExit", {"direction": dirs[how], "auto": how == "auto"})


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Pause"):
		if pause_sfx:
			pause_sfx.play()
		swap_pause_state()
