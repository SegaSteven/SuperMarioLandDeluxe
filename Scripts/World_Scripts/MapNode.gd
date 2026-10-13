extends Node2D

class_name MapNode
## A stop on the overworld map: a level, the start dock, a crossroads, or a portal to another map.
## Add MapPath children to connect it to other MapNodes (see MapPath.gd).

@export var level_name: String = ""        ## shown on the map UI. Also the ID used for "beaten" (e.g. "1-1")
@export var area_name: String = ""         ## e.g. "BIRABUTO"
@export_file("*.tscn") var level_scene_path: String = ""   ## empty = not a level (dock, crossroads...)
@export var spawn_point: Vector2 = Vector2.ZERO            ## where Mario starts INSIDE that level
@export var show_icon: bool = true
@export var idle_animation: StringName = &"Down"           ## Mario pose while standing here
@export_range(0, 3) var star_coins_in_level: int = 3        ## coins shown on the map HUD (0 = hide)
@export var required_unlock: String = ""                   ## secret level: icon hidden until this is unlocked (e.g. "star_road_1")

@export_group("Switch palace (optional)")
@export_enum("none", "blue", "red", "pink") var switch_color: String = "none"   ## makes this a switch palace: shows a switch icon
@export var replayable: bool = true                        ## switch palaces: can't be entered again once their switch is pressed

@export_group("Portal to another map (optional)")
@export_file("*.tscn") var goto_scene: String = ""
@export var goto_spawn_point: Vector2 = Vector2.ZERO       ## OverworldMan.spawn_point for the other map
@export var auto_goto: bool = true                         ## false = press jump to go through

@onready var icon: AnimatedSprite2D = get_node_or_null("AnimatedSprite2D")


func _enter_tree() -> void:
	add_to_group("map_nodes")


func _ready() -> void:
	refresh_icon()
	# Waiting for a reveal animation? Stay hidden until the path's reveal shows us.
	var waiting := required_unlock != "" and OverworldMan.pending_reveals.has(required_unlock)
	refresh_visibility(not waiting)


## Shows the stop if it isn't a locked secret. Pass false to keep it hidden for now.
func refresh_visibility(allow_show: bool = true) -> void:
	visible = allow_show and (required_unlock == "" or OverworldMan.is_unlocked(required_unlock))


## Can Mario enter this level right now? False for a switch palace whose switch is pressed.
func can_enter() -> bool:
	if not is_level():
		return false
	if is_switch_palace() and PowerUps.is_switch_on(switch_color):
		return false
	return replayable or not is_beaten()


func is_switch_palace() -> bool:
	return switch_color != "" and switch_color != "none"


## Placeholder switch-palace icon: a coloured switch with "!", squashed flat once pressed.
func _draw() -> void:
	if not is_switch_palace():
		return
	var c: Color = PowerUps.SWITCH_COLORS.get(switch_color, Color.WHITE)
	var ink := Color(0.1, 0.08, 0.05)
	if PowerUps.is_switch_on(switch_color):
		draw_rect(Rect2(-7, 3, 14, 4), c.darkened(0.3))
		draw_rect(Rect2(-7, 3, 14, 4), ink, false, 1.0)
	else:
		draw_rect(Rect2(-7, -7, 14, 14), c)
		draw_rect(Rect2(-7, -7, 14, 14), ink, false, 1.0)
		draw_rect(Rect2(-1, -4, 2, 5), Color.WHITE)
		draw_rect(Rect2(-1, 3, 2, 2), Color.WHITE)


func is_available() -> bool:
	return required_unlock == "" or OverworldMan.is_unlocked(required_unlock)


func is_level() -> bool:
	return level_scene_path != ""


func is_beaten() -> bool:
	return OverworldMan.is_beaten(level_name)


func refresh_icon() -> void:
	queue_redraw()
	if icon == null:
		return
	icon.visible = show_icon and is_level() and not is_switch_palace()
	if not icon.visible:
		return
	icon.play("complete" if is_beaten() else "unlocked")


## Returns the link to follow when `dir` (a MapPath.Dir value) is pressed, or {} if there's none.
## {"path": MapPath, "target": Node2D, "backwards": bool}
func get_link(dir: int) -> Dictionary:
	# Paths that start here
	for child in get_children():
		if child is MapPath and child.direction == dir and child.get_target() != null:
			return {"path": child, "target": child.get_target(), "backwards": false}
	# Paths that end here and can be walked backwards
	for p in get_tree().get_nodes_in_group("map_paths"):
		if p.bidirectional and p.get_target() == self and p.get_reverse_direction() == dir:
			return {"path": p, "target": p.get_source(), "backwards": true}
	return {}
