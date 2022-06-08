extends Area2D

var player = null

func can_see_player():
	return player != null

func _on_PlayerDetector_area_entered(area):
	player = area
