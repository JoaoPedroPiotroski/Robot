extends Area2D


func die():
	queue_free()


func _on_Coin_body_entered(body):
	GameInfo.score += 1
	var ui = get_parent().get_parent().get_node("CanvasLayer/UI")
	ui.get_node("Score").text = "Score: " + str(GameInfo.score)
	die()
