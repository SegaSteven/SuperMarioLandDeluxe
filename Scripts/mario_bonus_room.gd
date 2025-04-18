extends AnimatedSprite2D

signal mariostopped()
signal marionothing()
signal musicstop()

enum PlayerMode {
	SMALL,
	BIG,
	SHOOTING
}

var player_mode = PlayerMode.BIG

var mario_position = self.global_position
@export var max_walk_speed: float = 64
@onready var lives: Label = $"../Lives"

@onready var marioarea_2d: Area2D = $Area2D

@onready var area_2d: Area2D = $"../Ladder/Area2D"
@onready var ladder: Sprite2D = $"../Ladder"
var ladder_up = false
var ladder_down = false
var gravity = 350
var facing_dir = -1

# ladder areas:
@onready var down_area: Area2D = $"../Ladder/DownArea"
@onready var up_body: StaticBody2D = $"../Ladder/UpBody"

# raycast:
@onready var ray_cast_2d: RayCast2D = $RayCast2D

func _ready():
	lives.text = str(GameManager.lives)
	player_mode = GameManager.player_mode
	
	
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	lives.text = str(GameManager.lives)

func _on_bonus_room_mario_down_ladder() -> void:
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	play("%s_run" % animation_prefix)
	var runtween1 = get_tree().create_tween()
	runtween1.tween_property(self, "position", position + Vector2(64,0), 1)
	runtween1.chain().tween_property(self, "position", position + Vector2(64,24), 0.4)
	runtween1.chain().tween_property(self, "position", position + Vector2(106,24), 0.8).finished
	await runtween1.finished
	play("%s_idle" % animation_prefix)
	print("down ladder")


func _on_bonus_room_mario_up_ladder() -> void:
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	play("%s_run" % animation_prefix)
	var runtween1 = get_tree().create_tween()
	runtween1.tween_property(self, "position", position + Vector2(64,0), 1)
	runtween1.chain().tween_property(self, "position", position + Vector2(64,-24), 0.4)
	runtween1.chain().tween_property(self, "position", position + Vector2(106,-24), 0.8).finished
	await runtween1.finished
	play("%s_idle" % animation_prefix)
	print("up ladder")

func _on_bonus_room_mario_straight() -> void:
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	play("%s_run" % animation_prefix)
	var runtween1 = get_tree().create_tween()
	runtween1.tween_property(self, "position", position + Vector2(106,0), 1.8).finished
	await runtween1.finished
	play("%s_idle" % animation_prefix)
	print("no ladder")
	if Area2D == null:
		$"../Bonusgamebad".play()
		mariostopped.emit() 

func _on_bonus_1_up_area_entered(area: Area2D) -> void:
	print("touched 1")
	musicstop.emit()
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	var jumptween = get_tree().create_tween()
	play("%s_jump" % animation_prefix)
	jumptween.tween_property(self, "position", position + Vector2(0,0), 0)
	jumptween.chain().tween_property(self, "position", position + Vector2(0,-4), 0.5)
	$"1Up".play()
	jumptween.chain().tween_property(self, "position", position + Vector2(0,0), 0.5).finished
	await jumptween.finished
	GameManager.lives += 1
	play("%s_idle" % animation_prefix)
	mariostopped.emit()


func _on_bonus_2_up_area_entered(area: Area2D) -> void:
	print("touched 2")
	musicstop.emit()
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	var jumptween = get_tree().create_tween()
	play("%s_jump" % animation_prefix)
	jumptween.tween_property(self, "position", position + Vector2(0,0), 0)
	jumptween.chain().tween_property(self, "position", position + Vector2(0,-4), 0.5)
	$"1Up".play()
	jumptween.tween_property(self, "position", position + Vector2(0,0), 0.5).finished
	await jumptween.finished
	play("%s_idle" % animation_prefix)
	GameManager.lives += 1
	var jumptween2 = get_tree().create_tween()
	play("%s_jump" % animation_prefix)
	jumptween2.tween_property(self, "position", position + Vector2(0,0), 0)
	jumptween2.chain().tween_property(self, "position", position + Vector2(0,-4), 0.5)
	$"1Up".play()
	jumptween2.chain().tween_property(self, "position", position + Vector2(0,0), 0.5).finished
	await jumptween2.finished
	GameManager.lives += 1
	play("%s_idle" % animation_prefix)
	mariostopped.emit()


func _on_bonus_3_up_area_entered(area: Area2D) -> void:
	print("touched 3")
	musicstop.emit()
	var animation_prefix = PlayerMode.keys()[player_mode].to_snake_case()
	var jumptween = get_tree().create_tween()
	play("%s_jump" % animation_prefix)
	jumptween.tween_property(self, "position", position + Vector2(0,0), 0)
	jumptween.chain().tween_property(self, "position", position + Vector2(0,-4), 0.5)
	$"1Up".play()
	jumptween.chain().tween_property(self, "position", position + Vector2(0,0), 0.5).finished
	await jumptween.finished
	play("%s_idle" % animation_prefix)
	GameManager.lives += 1
	var jumptween2 = get_tree().create_tween()
	play("%s_jump" % animation_prefix)
	jumptween2.tween_property(self, "position", position + Vector2(0,0), 0)
	jumptween2.chain().tween_property(self, "position", position + Vector2(0,-4), 0.5)
	$"1Up".play()
	jumptween2.chain().tween_property(self, "position", position + Vector2(0,0), 0.5).finished
	await jumptween2.finished
	play("%s_idle" % animation_prefix)
	GameManager.lives += 1
	var jumptween3 = get_tree().create_tween()
	play("%s_jump" % animation_prefix)
	jumptween3.tween_property(self, "position", position + Vector2(0,0), 0)
	jumptween3.chain().tween_property(self, "position", position + Vector2(0,-4), 0.5)
	$"1Up".play()
	jumptween3.chain().tween_property(self, "position", position + Vector2(0,0), 0.5).finished
	await jumptween3.finished
	GameManager.lives += 1
	play("%s_idle" % animation_prefix)
	mariostopped.emit()


func _on_bonus_flower_area_entered(area: Area2D) -> void:
	musicstop.emit()
	if player_mode == PlayerMode.SHOOTING:
		marionothing.emit()
	elif player_mode == PlayerMode.BIG:
		$Bonusgamegood.play()
		$Powerup.play()
		GameManager.player_mode = Player.PlayerMode.SHOOTING
		PlayerMode.BIG
		play("big_idle")
		mariostopped.emit()
	else:
		$Powerup.play()
		GameManager.player_mode = Player.PlayerMode.SHOOTING
		PlayerMode.BIG
		play("big_idle")
		await get_tree().create_timer(0.1).timeout
		play("small_idle")
		await get_tree().create_timer(0.1).timeout
		play("big_idle")
		await get_tree().create_timer(0.1).timeout
		play("small_idle")
		await get_tree().create_timer(0.1).timeout
		play("big_idle")
		await get_tree().create_timer(0.1).timeout
		play("small_idle")
		await get_tree().create_timer(0.1).timeout
		play("big_idle")
		await get_tree().create_timer(0.1).timeout
		play("small_idle")
		await get_tree().create_timer(0.1).timeout
		play("big_idle")
		mariostopped.emit()
