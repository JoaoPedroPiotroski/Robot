extends Node2D

func _ready():
	$AnimationPlayer.play("Fade_Out")

func kill():
	queue_free()
