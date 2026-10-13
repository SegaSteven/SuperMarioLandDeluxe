extends PlayerState
## Mario's death: hop up, fall off screen, then reload the level (or game over).


func _init() -> void:
	allows_contacts = false
	allows_damage = false


func enter(_msg: Dictionary) -> void:
	player.is_dead = true
	player.velocity = Vector2.ZERO
	GameManager.player_mode = PlayerUpdated.PlayerMode.SMALL
	GameManager.lose_life(1)
	GameManager.clear_pending_star_coins()   # star coins only count if you finish the level

	player.stop_iframes()
	player.modulate.a = 1.0
	player.set_collision_layer_value(Layers.PLAYER, false)
	player.collision_mask = 0
	player.area_2d.set_deferred("monitoring", false)

	player.animated_sprite_2d.play("death")
	var music := player.get_parent().get_node_or_null("LevelMusic")
	if music:
		music.stop()
	player.get_node("11LoseLife").play()
	_run_death()


func _run_death() -> void:
	var tween := player.create_tween()
	tween.tween_property(player, "position", player.position + Vector2(0, -44), 0.5)
	tween.tween_property(player, "position", player.position + Vector2(0, 200), 1.2)
	await tween.finished
	await get_tree().create_timer(0.8).timeout
	if GameManager.is_game_over():
		GameManager.handle_game_over()
	else:
		get_tree().call_deferred("reload_current_scene")
