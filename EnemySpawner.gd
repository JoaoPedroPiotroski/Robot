extends Node2D

export var enemy : String = ""

onready var camera_detector = $CameraDetector

var can_spawn : bool = true

func _physics_process(_delta):
	if get_children().size() < 2 and can_spawn:
		var scene = load("res://Enemies/" + enemy + ".tscn")
		var enemy = scene.instance()
		add_child(enemy)
		for child in get_children():
			child.global_position = global_position


func _on_CameraDetector_area_entered(_area):
	if get_children().size() < 2 and can_spawn:
		var scene = load("res://Enemies/" + enemy + ".tscn")
		var enemy = scene.instance()
		add_child(enemy)
		for child in get_children():
			child.global_position = global_position
	can_spawn = false

func _on_CameraDetector_area_exited(_area):
	can_spawn = true
