extends Node
## Autoload "GameSettings": the Options menu's settings. Saved to user://settings.cfg and put
## back every time the game starts.
##   volume        0 - 10 (the whole game: music and sounds, the Master audio bus)
##   fullscreen    true / false
##   custom_keys   false = the keys from Project Settings > Input Map, true = the player's own

signal changed

const PATH := "user://settings.cfg"
const MAX_VOLUME := 10
## The actions the player can re-bind (Options > Key Binding > Custom), in menu order.
const BINDABLE: Array[String] = ["jump", "action", "left", "right", "Up", "down"]
const LABELS := {"jump": "JUMP", "action": "ACTION", "left": "LEFT", "right": "RIGHT", "Up": "UP", "down": "DOWN"}

var volume: int = 8
var fullscreen: bool = false
var custom_keys: bool = false
var custom_bindings: Dictionary = {}     # action -> InputEvent (the key the player picked)

var _default_events: Dictionary = {}     # action -> Array[InputEvent] from the Input Map
## false = Display Mode only remembers the choice without changing the window (for recording).
var apply_display_changes: bool = true


func _ready() -> void:
	for a in BINDABLE:
		if InputMap.has_action(a):
			_default_events[a] = InputMap.action_get_events(a).duplicate()
	load_settings()
	apply_all()


# --- Volume -------------------------------------------------------------------
func set_volume(v: int) -> void:
	volume = clampi(v, 0, MAX_VOLUME)
	_apply_volume()
	save_settings()
	changed.emit()


func _apply_volume() -> void:
	var bus := AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(bus, volume == 0)
	AudioServer.set_bus_volume_db(bus, linear_to_db(float(volume) / MAX_VOLUME) if volume > 0 else -80.0)


# --- Display ------------------------------------------------------------------
func set_fullscreen(on: bool) -> void:
	fullscreen = on
	_apply_display()
	save_settings()
	changed.emit()


func _apply_display() -> void:
	if DisplayServer.get_name() == "headless" or not apply_display_changes:
		return
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN if fullscreen else DisplayServer.WINDOW_MODE_WINDOWED)


# --- Keys ---------------------------------------------------------------------
func set_custom_keys(on: bool) -> void:
	custom_keys = on
	_apply_keys()
	save_settings()
	changed.emit()


## Gives an action a new key (Custom key binding). Keeps any controller buttons it already had.
func bind(action: String, event: InputEvent) -> void:
	custom_bindings[action] = event
	custom_keys = true
	_apply_keys()
	save_settings()
	changed.emit()


## The name of the key an action uses right now, e.g. "Z" or "Space".
func key_name(action: String) -> String:
	if not InputMap.has_action(action):
		return "-"
	for e in InputMap.action_get_events(action):
		if e is InputEventKey:
			var code: int = e.physical_keycode if e.physical_keycode != 0 else e.keycode
			return OS.get_keycode_string(code).to_upper()
	for e in InputMap.action_get_events(action):
		if e is InputEventJoypadButton:
			return "PAD %d" % e.button_index
	return "-"


func _apply_keys() -> void:
	for a in _default_events:
		InputMap.action_erase_events(a)
		var events: Array = _default_events[a]
		if custom_keys and custom_bindings.has(a):
			# the player's key replaces the keyboard keys; controller buttons stay
			InputMap.action_add_event(a, custom_bindings[a])
			for e in events:
				if not e is InputEventKey:
					InputMap.action_add_event(a, e)
		else:
			for e in events:
				InputMap.action_add_event(a, e)


# --- Saving -------------------------------------------------------------------
func apply_all() -> void:
	_apply_volume()
	_apply_display()
	_apply_keys()


func save_settings() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("audio", "volume", volume)
	cfg.set_value("display", "fullscreen", fullscreen)
	cfg.set_value("keys", "custom", custom_keys)
	for a in custom_bindings:
		var e: InputEvent = custom_bindings[a]
		if e is InputEventKey:
			cfg.set_value("keys", a, e.physical_keycode if e.physical_keycode != 0 else e.keycode)
	cfg.save(PATH)


func load_settings() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) != OK:
		return
	volume = clampi(int(cfg.get_value("audio", "volume", volume)), 0, MAX_VOLUME)
	fullscreen = bool(cfg.get_value("display", "fullscreen", fullscreen))
	custom_keys = bool(cfg.get_value("keys", "custom", false))
	custom_bindings.clear()
	for a in BINDABLE:
		if cfg.has_section_key("keys", a):
			var e := InputEventKey.new()
			e.physical_keycode = int(cfg.get_value("keys", a))
			custom_bindings[a] = e
