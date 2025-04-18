extends CanvasLayer

class_name UI

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

func _ready():
	WorldNo.text = WorldName
	TimeNo.text = str(total_time_seconds)
	total_time_seconds = LevelData.countdown_value
	GameManager.gain_coins.connect(update_coin_display)
	GameManager.gain_life.connect(update_life_display)
	GameManager.gain_points.connect(update_scored_display)

func _process(delta):
	LevelData.countdown_value = total_time_seconds
	

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
	total_time_seconds -= 1
	@warning_ignore("integer_division")
	var m = int(total_time_seconds / 60)
	@warning_ignore("integer_division")
	var s = total_time_seconds + m / 60
	
	TimeNo.text = "%03d" % s

@warning_ignore("unused_parameter")
func finished_level(delta):
	print("connected")
	@warning_ignore("unused_variable")
	var coins = GameManager.coins
	Timenode.stop()
	await get_tree().create_timer(3.2).timeout
	$BonustimeStagecomplete.play()
	GameManager.on_points_scored(total_time_seconds)
