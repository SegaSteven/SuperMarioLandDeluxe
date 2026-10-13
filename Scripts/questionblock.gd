extends Block

class_name QuestionBlock
## "?" block. Set `spawned_scene` in the Inspector. If it's the mushroom and Mario is already
## big, it gives a flower instead (like the real game). Tick `invisible` for hidden blocks.

@export var invisible: bool = false
@export var spawned_scene: PackedScene

const SHROOM = preload("res://Scenes/shroom.tscn")
const SHOOTING_FLOWER = preload("res://Scenes/shooting_flower.tscn")

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


func _scene_to_spawn() -> PackedScene:
	if spawned_scene == null:
		return null
	var is_mushroom := spawned_scene.resource_path == SHROOM.resource_path
	if is_mushroom and GameManager.player_mode != PlayerUpdated.PlayerMode.SMALL:
		return SHOOTING_FLOWER
	return spawned_scene


func spawn_item() -> void:
	var scene := _scene_to_spawn()
	if scene == null:
		return
	var item = scene.instantiate()
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
