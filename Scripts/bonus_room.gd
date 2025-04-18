extends Node

class_name BonusRoom

signal mario_straight
signal mario_down_ladder
signal mario_up_ladder

#ladder positions
const ladder_point1 = Vector2(80,68)
const ladder_point2 = Vector2(80,92)
const ladder_point3 = Vector2(80,116)

#mario positions
const mario_point1 = Vector2(16,120)
const mario_point2 = Vector2(16,96)
const mario_point3 = Vector2(16,72)
const mario_point4 = Vector2(16,48)

# bonus changes
var bonuses = ["1up", "2up", "3up2", "Flower"]
const bonus_point1 = Vector2(139.9, 51.9)
const bonus_point2 = Vector2(139.9, 75.7)
const bonus_point3 = Vector2(139.9, 99.7)
const bonus_point4 = Vector2(139.9, 123.7)
var bonus_points = [bonus_point1, bonus_point2, bonus_point3, bonus_point4]
var bonus_select = true
@onready var _1_up_bonus: AnimatedSprite2D = $"Bonuses/1upBonus"
@onready var _2_up_bonus: AnimatedSprite2D = $"Bonuses/2upBonus"
@onready var _3_up_bonus: AnimatedSprite2D = $"Bonuses/3upBonus"
@onready var flower_bonus: AnimatedSprite2D = $Bonuses/FlowerBonus
@onready var bonus_area: Area2D = $"Bonuses/1upBonus/BonusArea"
@onready var bonus_2_area: Area2D = $"Bonuses/2upBonus/Bonus2Area"
@onready var bonus_3_area: Area2D = $"Bonuses/3upBonus/Bonus3Area"
@onready var bonus_4_area: Area2D = $Bonuses/FlowerBonus/Bonus4Area


@export var prelevel: String
@export var nextlevel = "res://Scenes/WorldScenes/world_map.tscn"
@export var spawn_point: Vector2

@onready var mario: AnimatedSprite2D = $Mario
@onready var lives: Label = $Lives
@onready var ladder: Sprite2D = $Ladder
@onready var bonus_game: AudioStreamPlayer = $"BonusGame"
@onready var bonus_game_walk: AudioStreamPlayer = $BonusGameWalk
@onready var bonusgamebad: AudioStreamPlayer = $Bonusgamebad
@onready var bonusgamegood: AudioStreamPlayer = $Bonusgamegood

# ladder areas
@onready var down_area: Area2D = $Ladder/DownArea
@onready var up_body: StaticBody2D = $Ladder/UpBody


# mario area n raycast
@onready var ray_cast_2d: RayCast2D = $Mario/RayCast2D
@onready var area_2d: Area2D = $Mario/Area2D

# mario array
var mario_points = [mario_point1, mario_point2, mario_point3, mario_point4]
var mario_moving = true

# ladder array
var ladder_points = [ladder_point1, ladder_point2 , ladder_point3]
var ladder_moving = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	prelevel = GameManager.pre_level
	bonus_game.play()
	lives.text = str(GameManager.lives)
	item_position()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if Engine.get_process_frames() % 5 == 3:
		ladder_picker()
		mario_picker()
	if Input.is_action_just_pressed("jump"):
		ladder_moving = false
		mario_moving = false
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			if collider is StaticBody2D:
				mario_down_ladder.emit()
				bonus_game.stop()
				bonus_game_walk.play()
		if ray_cast_2d.is_colliding():
			var collider = ray_cast_2d.get_collider()
			if collider is Area2D:
				mario_up_ladder.emit()
				bonus_game.stop()
				bonus_game_walk.play()
		if not ray_cast_2d.is_colliding():
			mario_straight.emit()
			bonus_game.stop()
			bonus_game_walk.play()

func ladder_picker():
	var random_ladder = ladder_points.pick_random()
	var random_number = randi()
	if ladder_moving == true:
		ladder.position = random_ladder
	
func mario_picker():
	var random_mario = mario_points.pick_random()
	var random_number = randi()
	if mario_moving == true:
		mario.position = random_mario

func item_position():
	var random_point1 = bonus_points.pick_random()
	var random_point2 = bonus_points.pick_random()
	var random_point3 = bonus_points.pick_random()
	var random_point4 = bonus_points.pick_random()
	var random_number = randi()
	if  bonus_select == true:
		_1_up_bonus.position = random_point1
		if bonus_area.has_overlapping_areas():
			_1_up_bonus.position = random_point4
		_2_up_bonus.position = random_point2
		if bonus_2_area.has_overlapping_areas():
			_2_up_bonus.position = random_point3
		_3_up_bonus.position = random_point3
		if bonus_3_area.has_overlapping_areas():
			_3_up_bonus.position = random_point2
		flower_bonus.position = random_point4
		if bonus_4_area.has_overlapping_areas():
			flower_bonus.position = random_point1


	
func _on_up_area_area_entered(area: Area2D) -> void:
	if ray_cast_2d.is_colliding():
		mario_up_ladder.emit()


func _on_down_area_area_entered(area: Area2D) -> void:
	if ray_cast_2d.is_colliding():
		mario_down_ladder.emit()


func _on_bonus_area_area_entered(area: Area2D) -> void:
	var random_point = bonus_points.pick_random()
	_1_up_bonus.position = random_point
	print("changed1")

func _on_bonus_2_area_area_entered(area: Area2D) -> void:
	var random_point = bonus_points.pick_random()
	_2_up_bonus.position = random_point
	print("changed2")

func _on_bonus_3_area_area_entered(area: Area2D) -> void:
	var random_point = bonus_points.pick_random()
	_3_up_bonus.position = random_point
	print("changed3")

func _on_bonus_4_area_area_entered(area: Area2D) -> void:
	var random_point = bonus_points.pick_random()
	flower_bonus.position = random_point
	print("changed4")

func _on_mario_mariostopped() -> void:
	await get_tree().create_timer(1).timeout
	OverworldMan.spawn_point = spawn_point
	SceneManager.change_scene(nextlevel, {"pattern": "squares", "speed": 6})
	
func _on_mario_marionothing() -> void:
	bonusgamebad.play()
	await get_tree().create_timer(1).timeout
	OverworldMan.spawn_point = spawn_point
	SceneManager.change_scene(nextlevel, {"pattern": "squares", "speed": 6})


func _on_mario_musicstop() -> void:
	bonus_game_walk.stop()
