extends Node2D

var active : bool = false
var scene = load("res://Player/Ghost.tscn")
func _ready():
	get_node("RespawnTimer").start()

func _on_RespawnTimer_timeout():
	if active:
		var ghost = scene.instance()
		ghost.global_position = get_parent().global_position
		get_parent().get_parent().get_node("Ghosts").add_child(ghost)
		ghost.get_node("Sprite").frame = ghost.get_parent().get_parent().get_node("Player").get_node("Sprite").frame
		ghost.get_node("Sprite").flip_h = ghost.get_parent().get_parent().get_node("Player").get_node("Sprite").flip_h
	get_node("RespawnTimer").start()
