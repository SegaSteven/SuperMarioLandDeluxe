extends CanvasLayer

class_name UI

## TIME BONUS (end of level, like Super Mario Land):
## when Mario reaches the exit door or presses the boss switch, the clock stops, then counts
## down to 0 while every unit left is added to the score, with the "timerscore" sound.
## The door and BossSwitch call tally_time_bonus() for you. Settings below.

signal time_bonus_finished

@export_group("Time Bonus")
## Points for each unit of time left (Super Mario Land gives 10).
@export var points_per_time_unit: int = 10
## How fast the clock counts down during the tally, in units per second (400 left = ~3 s).
@export var tally_units_per_second: float = 130.0
## Sound played while counting. It restarts whenever it finishes so it keeps going until 0.
## Empty = res://Assets/SFX/timerscore.wav.
## (If you prefer a "tick" per unit, use bonustime_stagecomplete.wav and tick Restart Each Unit.)
@export var tally_sound: AudioStream
@export var restart_sound_each_unit: bool = false
@export_group("")

# References 
@onready var Lives = $LIVES
@onready var Score = $SCORE
@onready var Coins = $COINS
@onready var TimeNo = $TIMENO
@onready var WorldNo = $WORLDNO
@onready var Timenode = $Timer
@onready var total_time_seconds : int = 400

@export var WorldName: String

var countdown_current: float
var stopped = false
var timecountdown = false
var target_value = 0

const DEFAULT_TALLY_SOUND := "res://Assets/SFX/timerscore.wav"

var _tally_player: AudioStreamPlayer
var _tallying: bool = false


## The level's UI, or null if this scene has none.
static func find(tree: SceneTree) -> UI:
	return tree.get_first_node_in_group("level_ui") as UI


func _ready():
	add_to_group("level_ui")
	WorldNo.text = WorldName
	TimeNo.text = str(total_time_seconds)
	total_time_seconds = LevelData.countdown_value
	GameManager.gain_coins.connect(update_coin_display)
	GameManager.gain_life.connect(update_life_display)
	GameManager.gain_points.connect(update_scored_display)
	GameManager.lost_life.connect(update_life_display)

func _process(delta):
	LevelData.countdown_value = total_time_seconds
	update_coin_display(GameManager.coins)
	update_life_display(GameManager.lives)
	update_scored_display(GameManager.score)

@warning_ignore("unused_parameter")
func update_scored_display(points_scored):
	Score.text = str(GameManager.score)
	
@warning_ignore("unused_parameter")
func update_coin_display(coins_gained):
	Coins.text = str(GameManager.coins)

@warning_ignore("unused_parameter")
func update_life_display(life_gained):
	Lives.text = str(GameManager.lives)

func reset_timer():
	total_time_seconds = 400

func _on_timer_timeout():
	if stopped:
		return
	total_time_seconds = maxi(total_time_seconds - 1, 0)
	_show_time()


func _show_time() -> void:
	TimeNo.text = "%03d" % total_time_seconds


## Freezes the clock (the exit calls this the moment Mario touches it).
func stop_time() -> void:
	stopped = true
	Timenode.stop()


## Stops the clock, then counts the time left down to 0, adding points as it goes.
## Works while the game is paused. await it to wait until it's done.
func tally_time_bonus() -> void:
	stop_time()
	if _tallying:
		await time_bonus_finished
		return
	_tallying = true
	var old_mode := process_mode
	process_mode = Node.PROCESS_MODE_ALWAYS
	if _tally_player == null:
		_tally_player = AudioStreamPlayer.new()
		_tally_player.name = "TallySound"
		_tally_player.process_mode = Node.PROCESS_MODE_ALWAYS
		var bus := $BonustimeStagecomplete as AudioStreamPlayer
		if bus:
			_tally_player.bus = bus.bus
		add_child(_tally_player)
	if tally_sound == null and ResourceLoader.exists(DEFAULT_TALLY_SOUND):
		tally_sound = load(DEFAULT_TALLY_SOUND)
	_tally_player.stream = tally_sound

	var owed := 0.0
	var last := Time.get_ticks_usec()
	while total_time_seconds > 0:
		await get_tree().process_frame
		var now := Time.get_ticks_usec()
		owed += (now - last) / 1000000.0 * tally_units_per_second
		last = now
		var units := mini(int(owed), total_time_seconds)
		if units <= 0:
			continue
		owed -= units
		total_time_seconds -= units
		LevelData.countdown_value = total_time_seconds
		GameManager.on_points_scored(units * points_per_time_unit)
		_show_time()
		update_scored_display(GameManager.score)
		if tally_sound and (restart_sound_each_unit or not _tally_player.playing):
			_tally_player.play()
	if _tally_player.playing and not restart_sound_each_unit:
		_tally_player.stop()
	process_mode = old_mode
	_tallying = false
	time_bonus_finished.emit()


## Old name kept so anything already connected to it still works.
@warning_ignore("unused_parameter")
func finished_level(delta = null):
	await tally_time_bonus()
