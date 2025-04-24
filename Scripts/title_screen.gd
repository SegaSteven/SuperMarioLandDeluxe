extends Node

@onready var ui_data = preload("res://Scripts/ui.gd")
@onready var ScoreCard = $SCORE
@export var next_scene = "res://Scenes/Letter_Screen.tscn"
@onready var title_logo: Sprite2D = $Background/TitleLogo
@onready var deluxe: AnimatedSprite2D = $Background/Deluxe

var title_done = false

# Called when the node enters the scene tree for the first time.
func _ready():
	$TitleScreen.play()

func set_score(points: int):
	ScoreCard.text = "%d" % points
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Start"):
		SceneManager.change_scene(next_scene, {"pattern": "vertical", "speed": 4})
