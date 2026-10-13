extends Area2D

class_name StarCoin
## A special coin - put 3 in each level (New Super Mario Bros style).
##
## Setup: instance res://Scenes/star_coin.tscn in a level and set Coin Number to 1, 2 or 3.
## Each level needs one of each number. They work in underground rooms too.
##   - Collected coins only save when you FINISH the level (either exit). Die and they come back.
##   - A coin you already saved on an earlier run shows see-through. Grabbing it again just
##     gives points.
##   - The map shows them under the level name: filled = got it, hollow = still to find.

@export_range(1, 3) var coin_number: int = 1
@export var points: int = 2000
@export var bob_height: float = 2.0

@onready var sprite: Sprite2D = get_node_or_null("Sprite2D")

var _collected: bool = false
var _already_saved: bool = false


func _ready() -> void:
	collision_layer = 0
	collision_mask = Layers.bit(Layers.PLAYER)
	body_entered.connect(_on_body_entered)

	var index := coin_number - 1
	if GameManager.pending_star_coins.has(index):
		queue_free()          # picked up earlier this run (e.g. before going down a pipe)
		return
	_already_saved = OverworldMan.has_star_coin(OverworldMan.level_name, index)
	if _already_saved:
		modulate.a = 0.4      # "ghost" coin: you've got it already

	if sprite and bob_height > 0.0:
		var tween := create_tween().set_loops()
		tween.tween_property(sprite, "position:y", -bob_height, 0.5).set_trans(Tween.TRANS_SINE)
		tween.tween_property(sprite, "position:y", 0.0, 0.5).set_trans(Tween.TRANS_SINE)


func _on_body_entered(body: Node2D) -> void:
	if _collected or not body is PlayerUpdated or body.is_dead:
		return
	_collected = true
	GameManager.collect_star_coin(coin_number - 1)
	GameManager.on_points_scored(points)
	body.spawn_points_label_bonus(points, global_position)

	var sfx := get_node_or_null("Collect") as AudioStreamPlayer
	if sfx:
		sfx.play()
	set_deferred("monitoring", false)
	var tween := create_tween()
	tween.tween_property(self, "position:y", position.y - 16, 0.4)
	tween.parallel().tween_property(self, "modulate:a", 0.0, 0.4)
	tween.tween_interval(0.3)   # let the sound finish
	tween.tween_callback(queue_free)
