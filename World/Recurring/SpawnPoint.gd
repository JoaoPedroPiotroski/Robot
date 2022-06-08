extends Area2D



func _on_SpawnPoint_body_entered(body):
	GameInfo.start_pos = $Point.global_position
