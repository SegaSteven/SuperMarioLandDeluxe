extends CanvasLayer

class_name WorldUI
## Map HUD: level name, area name, lives, and the 3 star coins for the level Mario stands on
## (filled = collected, hollow = still to find). Only updates when something changes.

const COIN_FILLED := preload("res://Assets/Sprites/StarCoin/star_coin_filled.png")
const COIN_EMPTY := preload("res://Assets/Sprites/StarCoin/star_coin_empty.png")

## Where the coin icons go on screen (top-left of the first coin). Move them here, or add your
## own HBoxContainer called "StarCoins" to world_ui.tscn and it will be used instead.
@export var coins_position: Vector2 = Vector2(186, 16)
@export var coin_spacing: int = 1

@onready var level_name = $LevelName
@onready var world_area = $WorldArea
@onready var lives: Label = $Lives
@onready var mario_map: AnimatedSprite2D = $MarioMap

var _coin_box: HBoxContainer
var _coin_icons: Array[TextureRect] = []
var _shown_key: String = ""


func _ready() -> void:
	GameManager.gain_life.connect(func(_n): update_lives())
	GameManager.lost_life.connect(func(_n): update_lives())
	update_lives()
	_build_coin_icons()


func _build_coin_icons() -> void:
	_coin_box = get_node_or_null("StarCoins") as HBoxContainer
	if _coin_box == null:
		_coin_box = HBoxContainer.new()
		_coin_box.name = "StarCoins"
		_coin_box.position = coins_position
		_coin_box.add_theme_constant_override("separation", coin_spacing)
		add_child(_coin_box)
	for child in _coin_box.get_children():
		child.queue_free()
	for i in 3:
		var icon := TextureRect.new()
		icon.texture = COIN_EMPTY
		icon.stretch_mode = TextureRect.STRETCH_KEEP
		_coin_box.add_child(icon)
		_coin_icons.append(icon)


func _process(_delta: float) -> void:
	var lname := str(OverworldMan.level_name)
	var aname := str(OverworldMan.area_name)
	var total := OverworldMan.current_star_coin_total
	var got := OverworldMan.star_coins_for(lname)
	# One cheap string compare per frame; the labels/icons only change when this does
	var key := "%s|%s|%d|%s" % [lname, aname, total, got]
	if key == _shown_key:
		return
	_shown_key = key
	level_name.text = lname
	world_area.text = aname
	_coin_box.visible = total > 0
	for i in _coin_icons.size():
		_coin_icons[i].visible = i < total
		_coin_icons[i].texture = COIN_FILLED if got[i] else COIN_EMPTY


func update_level_name():
	level_name.text = str(OverworldMan.level_name)

func update_lives():
	lives.text = str(GameManager.lives)

func update_area_name():
	world_area.text = str(OverworldMan.area_name)
