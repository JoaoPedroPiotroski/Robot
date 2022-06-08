extends StaticBody2D

export var destination : String
var fixed_destination = ""

export var direction : int = 1

export var new_portal : String

var player_is_in : bool = false

func _ready():
	if GameInfo.go_portal == name:
		GameInfo.is_new_level = false
		GameInfo.start_pos = global_position
		GameInfo.go_portal = ""
		get_parent().get_node("Player").global_position = Vector2(global_position.x + direction * 32, global_position.y)
	fixed_destination = "res://World/Levels/" + destination + ".tscn"
	
func _process(_delta):
	if Input.is_action_just_pressed("up") and player_is_in:
		GameInfo.go_portal = new_portal
		GameInfo.is_new_level = true
		change_scene()

func change_scene():
	player_is_in = false
	var _foo = get_tree().change_scene(fixed_destination)


func _on_Area2D_body_entered(body):
	if body is KinematicBody2D:
		player_is_in = true

func _on_Area2D_body_exited(body):
	if body is KinematicBody2D:
		player_is_in = false
