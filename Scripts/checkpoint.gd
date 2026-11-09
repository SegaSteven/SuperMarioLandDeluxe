@tool
extends Node2D

class_name Checkpoint
## A checkpoint (the invisible half-way points of Super Mario Land).
## When Mario walks through it, it becomes his restart point: if he loses a life, the level
## starts again HERE instead of at the beginning - even if he died down a pipe afterwards.
## It's forgotten when he goes back to the map or finishes the level.
##
## ADDING ONE: drag res://Scenes/checkpoint.tscn into a level (any parent node) and move it.
##   - Mario restarts at its position (+ Spawn Offset) and drops onto the floor below, so it
##     doesn't need to sit exactly on the ground.
##   - The trigger is the Area2D's CollisionShape2D. Make it tall (scale the checkpoint or the
##     shape) so Mario can't jump over it.
##   - The little flag only shows in the editor. Tick Show In Game to see it while testing.
##
## Several checkpoints in a level: the one furthest to the RIGHT that Mario has touched wins,
## so walking back past an earlier one doesn't move his restart point backwards
## (untick Only Forward to allow that).

signal reached

@export var spawn_offset: Vector2 = Vector2.ZERO     ## restart point relative to the checkpoint
@export var only_forward: bool = true                 ## don't replace a checkpoint further right
@export var show_in_game: bool = false:               ## draw the flag in the game too (testing)
	set(v):
		show_in_game = v
		queue_redraw()
@export var reach_sound: AudioStream                  ## optional sound when it's touched
## Old setting: makes this checkpoint active as soon as the level starts.
@export var spawnpoint: bool = false

var activated: bool = false


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	var area := get_node_or_null("Area2D") as Area2D
	if area:
		area.collision_layer = 0
		area.collision_mask = Layers.bit(Layers.PLAYER)
		if not area.area_entered.is_connected(_on_area_2d_area_entered):
			area.area_entered.connect(_on_area_2d_area_entered)
	# Already Mario's restart point (we're back after losing a life)
	if GameManager.is_current_checkpoint(self):
		activated = true
		GameManager.current_checkpoint = self
	elif spawnpoint and not GameManager.has_checkpoint_in(GameManager._scene_of(self)):
		activate()


## Where Mario starts again from this checkpoint.
func spawn_position() -> Vector2:
	return global_position + spawn_offset


func activate() -> void:
	if GameManager.set_checkpoint(self, spawn_position(), only_forward):
		activated = true
		reached.emit()
		if reach_sound:
			var p := AudioStreamPlayer.new()
			p.stream = reach_sound
			add_child(p)
			p.play()
			p.finished.connect(p.queue_free)
		queue_redraw()


func _on_area_2d_area_entered(area: Area2D) -> void:
	if Engine.is_editor_hint() or activated:
		return
	var mario := area.get_parent() as PlayerUpdated
	if mario and not mario.is_dead:
		activate()


## Placeholder flag (editor only unless Show In Game is ticked). Undoes the node's scale so a
## stretched checkpoint still shows a normal-sized flag.
func _draw() -> void:
	if not Engine.is_editor_hint() and not show_in_game:
		return
	var s := global_scale
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(1.0 / maxf(s.x, 0.001), 1.0 / maxf(s.y, 0.001)))
	var col := Color(0.2, 0.9, 0.3) if activated else Color(1, 0.85, 0.2)
	draw_line(Vector2(0, 0), Vector2(0, -16), Color(0.9, 0.9, 0.9), 1.0)
	draw_colored_polygon(PackedVector2Array([Vector2(0, -16), Vector2(8, -13), Vector2(0, -10)]), col)
	draw_circle(spawn_offset, 1.5, Color(0.3, 0.7, 1.0))   # the restart point
