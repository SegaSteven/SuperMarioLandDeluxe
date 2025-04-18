extends StaticBody2D

class_name LiftPlatform

@onready var blockhititem: AudioStreamPlayer = $Blockhititem


@export var speed = -10

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	blockhititem.play()

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	position += Vector2(0,speed) * delta
