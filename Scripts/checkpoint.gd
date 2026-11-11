@tool
extends Node2D

class_name Checkpoint
## A checkpoint (the half-way points of Super Mario Land): a marker standing on the ground.
## As soon as Mario gets PAST its x position - at any height, even over the top of the screen -
## it becomes his restart point: if he loses a life, the level starts again HERE instead of at
## the beginning (even if he died down a pipe afterwards). It's forgotten when he goes back to
## the map or finishes the level.
##
## ADDING ONE: drag res://Scenes/checkpoint.tscn into a level and put it on the ground where it
## should be. That's all - no trigger box to size. In the editor a dashed line shows the point
## Mario has to pass (CHECKPOINT), and the flag sprite stands on the ground.
##
## LEVEL START: tick Spawnpoint and it's the start of the level instead - it's active from the
## moment the level starts (if Mario hasn't reached a later one), its sprite is hidden, and the
## editor line says START.
##
## THE SPRITE: the AnimatedSprite2D child (called Sprite, placeholder frames) plays:
##   idle      - before Mario gets there (can loop)
##   activate  - plays ONCE when he passes it (Loop off)
##   active    - the 1-frame sprite it switches to afterwards (and keeps after a lost life)
## Change the animation names under Sprite if you use different ones.
##
## Several checkpoints in a level: the one furthest to the RIGHT that Mario has reached wins,
## so going back past an earlier one doesn't move his restart point backwards
## (untick Only Forward to allow that).

signal reached

@export var spawn_offset: Vector2 = Vector2.ZERO     ## restart point relative to the checkpoint
@export var only_forward: bool = true                 ## don't replace a checkpoint further right
@export var reach_sound: AudioStream                  ## optional sound when Mario reaches it
## The start of the level (active from the start, sprite hidden).
@export var spawnpoint: bool = false:
	set(v):
		spawnpoint = v
		queue_redraw()
## Draw the dashed line in the game too (testing).
@export var show_in_game: bool = false:
	set(v):
		show_in_game = v
		queue_redraw()
## How tall the dashed line is in the editor (it goes up from the checkpoint).
@export var line_height: float = 144.0:
	set(v):
		line_height = v
		queue_redraw()

@export_group("Sprite")
@export var anim_idle: StringName = &"idle"
@export var anim_activate: StringName = &"activate"
@export var anim_active: StringName = &"active"
@export_group("")

var activated: bool = false
var _sprite: AnimatedSprite2D


func _ready() -> void:
	queue_redraw()
	if Engine.is_editor_hint():
		return
	_sprite = _find_sprite()
	if _sprite:
		_sprite.visible = not spawnpoint
		if not _sprite.animation_finished.is_connected(_on_sprite_animation_finished):
			_sprite.animation_finished.connect(_on_sprite_animation_finished)
	# Already Mario's restart point (we're back after losing a life)
	if GameManager.is_current_checkpoint(self):
		activated = true
		GameManager.current_checkpoint = self
		_show(anim_active)
	else:
		_show(anim_idle)
	if not activated and spawnpoint and not GameManager.has_checkpoint_in(GameManager._scene_of(self)):
		activate()


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint() or activated or spawnpoint:
		return
	var m := GameManager.player as PlayerUpdated
	if m == null or not is_instance_valid(m) or m.is_dead or not m.is_inside_tree():
		return
	if m.get_tree().current_scene != get_tree().current_scene:
		return
	if m.global_position.x >= global_position.x:
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
		if _has_anim(anim_activate):
			_sprite.play(anim_activate)
		else:
			_show(anim_active)
		queue_redraw()
	else:
		activated = true          # an earlier checkpoint than the one Mario already has


func _find_sprite() -> AnimatedSprite2D:
	for c in get_children():
		if c is AnimatedSprite2D:
			return c
	return null


func _has_anim(a: StringName) -> bool:
	return _sprite != null and _sprite.sprite_frames != null and _sprite.sprite_frames.has_animation(a)


func _show(a: StringName) -> void:
	if _has_anim(a):
		_sprite.play(a)


func _on_sprite_animation_finished() -> void:
	if _sprite.animation == anim_activate:
		_show(anim_active)


## The dashed line Mario has to pass (editor only, unless Show In Game is ticked).
func _draw() -> void:
	if not Engine.is_editor_hint() and not show_in_game:
		return
	var col := Color(0.3, 0.6, 1.0) if spawnpoint else (Color(0.2, 0.9, 0.3) if activated else Color(1, 0.85, 0.2))
	var y := 0.0
	while y > -line_height:
		draw_line(Vector2(0, y), Vector2(0, maxf(y - 4.0, -line_height)), col, 1.0)
		y -= 8.0
	draw_line(Vector2(-6, 0), Vector2(6, 0), col, 1.0)
	draw_circle(spawn_offset, 1.5, Color(0.3, 0.7, 1.0))   # the restart point
	draw_string(ThemeDB.fallback_font, Vector2(2, -line_height + 6), "START" if spawnpoint else "CHECKPOINT",
		HORIZONTAL_ALIGNMENT_LEFT, -1, 6, col)
