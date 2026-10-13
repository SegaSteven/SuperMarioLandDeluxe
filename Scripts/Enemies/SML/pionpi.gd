extends HopperEnemy

class_name Pionpi
## Pionpi (World 4, Chai): a hopping jiangshi. Hops quickly towards Mario.
## Stomping only knocks it flat for a moment - it gets back up. Only a superball defeats it.

@export var revive_time: float = 2.5

var _flat: bool = false


func _on_ready() -> void:
	super._on_ready()


func _alive_physics(delta: float) -> void:
	if _flat:
		apply_gravity(delta)
		velocity.x = 0.0
		move_and_slide()
		return
	super._alive_physics(delta)


func stomp(_player: Node) -> void:
	if _flat:
		return
	_flat = true
	_play_anim("dead")
	_play_sfx("Enemykilled")
	get_tree().create_timer(revive_time, false).timeout.connect(_revive)


func _revive() -> void:
	if is_dead or not is_inside_tree():
		return
	_flat = false
	_play_anim(anim_ground)


## Lying flat it's harmless.
func touch_player(player: Node) -> void:
	if not _flat:
		super.touch_player(player)
