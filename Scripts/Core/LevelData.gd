extends Node

signal level_start()

var countdown_value : int = 400
var level_completed = false

var level_dic = {
	"level1" :{
		"unlocked" : true,
		"score" : 0,
		"max_score" : 0,
		"coins" : 0,
		"max_coins" : 0,
		"unlocks" : "level2",
		"beaten" : false
	}
}

func generate_level(level):
	if level not in level_dic:
		level_dic[level] = {
			"unlocked" : false,
			"score" : 0,
			"max_score" : 0,
			"coins" : 0,
			"max_coins" : 0,
			"unlocks" : generate_level_number(level),
			"beaten" : false
		}

func generate_level_number(level):
	var level_number = ""
	for character in level:
		if character.is_valid_int():
			level_number += character
	level_number = int(level_number) + 1
	return "level" + str(level_number)

func update_level(level, score, max_score, coins, max_coins, beaten):
	level_dic[level]["score"] = score
	level_dic[level]["max_score"] = max_score
	level_dic[level]["coins"] = coins
	level_dic[level]["max_coins"] = max_coins
	level_dic[level]["beaten"] = beaten

var score: int = 0
var coins: int = 0
var lives: int = 0

# Coins handling
var coin_queue: int = 0

@export var ui: UI
@export var player: PlayerUpdated
@export var level_music : AudioStreamPlayer
## Music while the game is paused (the Paused box). Empty = the file
## res://Assets/Audio/pause_music.wav / .ogg / .mp3 if it's there, otherwise silence.
@export var pause_music: AudioStream
var beaten = false

var music_position = 0
var firsttime_load = false

# OnReady references ----------------------------------------------------------
@onready var PLAYER_SCENE = preload("res://Scenes/player.tscn")
@onready var pause_label = get_node_or_null("Pause")

# Coins reach this number a 1up is given
const num_coins_for_1up: int = 100

# maximum number of lives that mario can have. --------------------------------
const max_num_lives: int = 99

# maximum number of coins that mario can collect at once ----------------------
const max_num_coins: int = 100


# Called when the node enters the scene tree for the first time.
#func _ready():

	#player.castle_entered.connect(ui.on_finish)
	
	#if SceneData.points_global != 0:
		#SceneData.points_global = points
		#ui.set_score(points)
	#if SceneData.lives_global != 0:
		#SceneData.lives_global = lives
		#ui.set_lives(lives)
	#if SceneData.coins_global != 0:
		#SceneData.coins_global = coins
		#ui.set_coins(coins)



func save_state():
	GameManager.points_global = score
	GameManager.coins_global = coins
#
func load_state():
	GameManager.gain_coins.emit(coins)
	GameManager.gain_points.emit(score)

func fresh_start():
	pass

func win_level():
	GameManager.win()

## Pause pressed in a level: opens the Paused box (Scripts/UI/options_menu.gd) and pauses the
## game and the level music. Pause again (handled by the box) carries on. The box's
## "Exit Level" goes back to the map, "Exit to Title" to the title screen.
const PAUSE_MUSIC_FILES := ["res://Assets/Audio/pause_music.wav", "res://Assets/Audio/pause_music.ogg", "res://Assets/Audio/pause_music.mp3"]
const TITLE_SCENE := "res://Scenes/title_screen.tscn"
const DEFAULT_MAP_SCENE := "res://Scenes/WorldScenes/world_map.tscn"

var _pause_menu: OptionsMenu
var _pause_music_player: AudioStreamPlayer
var _pause_exit: String = ""


func swap_pause_state():
	if pause_label:
		pause_label.hide()            # the old PAUSE bar isn't used any more
	if _pause_menu and is_instance_valid(_pause_menu):
		_pause_menu.close()
		return
	if get_tree().paused:
		return                        # something else has paused the game (e.g. the exit fanfare)
	if is_instance_valid(player) and player.is_dead:
		return
	get_tree().paused = true
	Engine.time_scale = 0.0           # freezes everything in the level, even "Always" nodes (the timer...)
	if level_music:
		music_position = level_music.get_playback_position()
		level_music.stream_paused = true
	_play_pause_music()
	_pause_exit = ""
	_pause_menu = OptionsMenu.open_paused(get_tree())
	_pause_menu.chosen.connect(_on_pause_chosen)
	_pause_menu.closed.connect(_on_pause_closed)


func is_paused_menu_open() -> bool:
	return _pause_menu != null and is_instance_valid(_pause_menu)


func _play_pause_music() -> void:
	var stream := pause_music
	if stream == null:
		for path in PAUSE_MUSIC_FILES:
			if ResourceLoader.exists(path):
				stream = load(path)
				break
	if stream == null:
		return
	if _pause_music_player == null:
		_pause_music_player = AudioStreamPlayer.new()
		_pause_music_player.name = "PauseMusic"
		_pause_music_player.process_mode = Node.PROCESS_MODE_ALWAYS
		add_child(_pause_music_player)
	_pause_music_player.stream = stream
	_pause_music_player.play()


func _on_pause_chosen(item: String) -> void:
	_pause_exit = item
	_pause_menu.close()


func _on_pause_closed() -> void:
	_pause_menu = null
	if _pause_music_player:
		_pause_music_player.stop()
	Engine.time_scale = 1.0
	get_tree().paused = false
	match _pause_exit:
		"Exit Level":
			GameManager.clear_pending_star_coins()
			var map := OverworldMan.last_map_scene
			if map == "" or not ResourceLoader.exists(map):
				map = DEFAULT_MAP_SCENE
			OverworldMan.spawn_point = Vector2.ZERO
			GameManager.travel_to(map, Vector2.ZERO, {"pattern": "squares", "speed": 4})
		"Exit to Title":
			GameManager.clear_pending_star_coins()
			GameManager.clear_checkpoint()
			GameManager.reset_game_state()
			SceneManager.change_scene(TITLE_SCENE, {"pattern": "squares", "speed": 4})
		_:
			if level_music:
				level_music.stream_paused = false
				if not level_music.playing:
					level_music.play(music_position)
