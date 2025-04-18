extends Node

@export var path_follow: PathFollow2D


# will be speed in pixels per second
@export var speed = 50

func _process(delta):
	path_follow.progress += speed * delta
