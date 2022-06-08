extends Area2D

signal arena_entered

func _on_BossArenaEntered_body_entered(body):
	emit_signal("arena_entered")
	get_parent().get_node("BossCamera").current = true
	get_parent().get_node("Boss1").fight_started = true
	body.global_position = get_parent().get_node("Position2D").global_position
	get_parent().get_node("BossDoor").activate()
	queue_free()
