extends Block

class_name BlockWItem

enum BonusType {
	COIN,
}

#Bonus References
const COIN_SCENE = preload("res://Scenes/coin.tscn")

@onready var animated_sprite_2d = $AnimatedSprite2D
@export var invisible: bool = false
@export var spawned_scene: PackedScene

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

func spawn_item():
	var spawned_scene = spawned_scene.instantiate()
	spawned_scene.global_position = global_position + Vector2(0,-4)
	get_tree().root.add_child(spawned_scene)
	
