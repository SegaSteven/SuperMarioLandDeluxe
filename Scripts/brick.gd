extends Block

class_name Brick

@onready var gpu_particles_2d = $GPUParticles2D
@onready var sprite_2d = $Sprite2D

func bump(player_mode: Player.PlayerMode):
	if player_mode == Player.PlayerMode.SMALL:
		super.bump(player_mode)
		$HitHardBlock.play()
	
	elif !gpu_particles_2d.emitting:
		set_collision_layer_value(5, false)
		gpu_particles_2d.emitting = true
		$Blockdead.play()
		$Sprite2D.visible = false
		super.check_for_enemy_collision()

func _on_gpu_particles_2d_finished():
	queue_free()
