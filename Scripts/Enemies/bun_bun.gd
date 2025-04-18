extends Enemy

class_name BunBun

@export var score = 800

@onready var ray_cast_bunbun: RayCast2D = $RayCast2D

@export var spawned_scene: PackedScene
var fired_too_recenly = true
var flying = true

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	set_process(false)
	self.add_to_group("enemy")


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position.x -= delta * horizontal_speed
	if flying == true:
		horizontal_speed = 80
	elif flying == false:
		horizontal_speed = 0
	if ray_cast_bunbun.is_colliding() && flying == true && fired_too_recenly == true:
		fired_too_recenly = false
		flying = false
		horizontal_speed = 0
		await get_tree().create_timer(0.5).timeout
		if fired_too_recenly == false:
			var spawned_scene = spawned_scene.instantiate()
			spawned_scene.global_position = global_position + Vector2(0,4)
			get_tree().root.add_child(spawned_scene)
			await get_tree().create_timer(0.5).timeout
			flying = true
		
	
func die():
	set_collision_layer_value(3 ,false)
	flying = false
	horizontal_speed = 0
	var deadtween = get_tree().create_tween()
	deadtween.tween_property(self, "position", position + Vector2(0, -30), 1.5)
	super.die()
	await get_tree().create_timer(1.5).timeout
	queue_free()

func _on_visible_on_screen_notifier_2d_screen_entered():
	set_process(true)
	

func _on_visible_on_screen_notifier_2d_screen_exited():
	queue_free()


func _on_body_entered(body: Superball) -> void:
	set_collision_layer_value(3, false)
	set_collision_mask_value(1, false)
	set_collision_mask_value(4, false)
	set_collision_mask_value(5, false)
	set_collision_mask_value(7, false)
	die_from_hit()
