extends Block

class_name QuestionBlock

enum BonusType {
	COIN,
}

@onready var player: Player = $"../../Player"
const Player = preload("res://Scripts/player.gd")

#Bonus References
const COIN_SCENE = preload("res://Scenes/coin.tscn")

@onready var animated_sprite_2d = $AnimatedSprite2D
@export var invisible: bool = false
@export var spawned_scene: PackedScene

# spawn types ------------------------------------------------------------------
const SHROOM = preload("res://Scenes/shroom.tscn")
const SHOOTING_FLOWER = preload("res://Scenes/shooting_flower.tscn")

var is_empty = false

func _ready():
	animated_sprite_2d.visible = !invisible

func bump(player_mode: Player.PlayerMode):
	if is_empty:
		$HitHardBlock.play()
		return	
	if invisible:
		animated_sprite_2d.visible = true
		invisible = !invisible
	else:
		spawn_item()
	super.bump(player_mode)
	make_empty()
	
func make_empty():
	is_empty = true
	animated_sprite_2d.play("empty")

func change_powerup():
	if player.player_mode == Player.PlayerMode.SMALL && spawned_scene == SHROOM:
		spawned_scene = SHROOM
	if player.player_mode == Player.PlayerMode.BIG && spawned_scene == SHROOM:
		spawned_scene = SHOOTING_FLOWER

func spawn_item():
	change_powerup()
	var spawned_scene = spawned_scene.instantiate()
	spawned_scene.global_position = global_position + Vector2(0,-4)
	get_tree().root.add_child(spawned_scene)
	
