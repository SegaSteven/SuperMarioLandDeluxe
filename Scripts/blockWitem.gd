extends Block

class_name BlockWItem

@export var invisible: bool = false
@export var spawned_scene: PackedScene

@onready var animated_sprite_2d = $AnimatedSprite2D

var is_empty: bool = false


func _ready() -> void:
	animated_sprite_2d.visible = not invisible


func bump(player_mode: PlayerUpdated.PlayerMode) -> void:
	if is_empty:
		$HitHardBlock.play()
		return
	if invisible:
		animated_sprite_2d.visible = true
		invisible = false
	else:
		spawn_item()
	super.bump(player_mode)
	make_empty()


func make_empty() -> void:
	is_empty = true
	animated_sprite_2d.play("empty")


func spawn_item() -> void:
	if spawned_scene == null:
		return
	var item = spawned_scene.instantiate()
	item = locked_fallback(item)
	item.global_position = global_position + Vector2(0, -4)
	get_tree().current_scene.add_child(item)


## A power-up that isn't unlocked yet (bunny ears, speed shoes...) is swapped for a normal one:
## a mushroom for small Mario, a Superball Flower otherwise.
static func locked_fallback(item: Node) -> Node:
	if not item is PowerUpItem or PowerUps.is_unlocked(item.power_up_id):
		return item
	item.free()
	var small := GameManager.player_mode == PlayerUpdated.PlayerMode.SMALL
	var path := "res://Scenes/shroom.tscn" if small else "res://Scenes/shooting_flower.tscn"
	return load(path).instantiate()
