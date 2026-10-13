extends FlyerEnemy

class_name Gunion
## Gunion (World 2-3): bobs up and down in the water. Two torpedoes split it into two halves
## that zoom straight at Mario.

@export var shard_scene: PackedScene = preload("res://Scenes/Enemies/Bosses/boss_fireball.tscn")
@export var shard_speed: float = 80.0


func _init() -> void:
	# defaults; the Inspector can still change them
	pattern = Pattern.PATROL_UP_DOWN
	hits_to_kill = 2
	score = 800


func _begin_death() -> void:
	super._begin_death()
	var p := get_player()
	if shard_scene == null or p == null:
		return
	for offset in [Vector2(0, -6), Vector2(0, 6)]:
		var shard = shard_scene.instantiate()
		shard.global_position = global_position + offset
		if "launch_velocity" in shard:
			shard.launch_velocity = (p.global_position - shard.global_position).normalized() * shard_speed
		get_tree().current_scene.call_deferred("add_child", shard)
