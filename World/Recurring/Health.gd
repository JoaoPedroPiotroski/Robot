extends Area2D

export var heal_amount : int = 1

var can_heal : bool = false

onready var sprite = $Sprite

func _ready():
	$Sprite.material.set("shader_param/active", 0.0)

#func _process(_delta):
#	var scale = heal_amount
#	if scale > 1:
#		scale *= 0.6
#	scale = int(scale) * 2
#	scale = min(scale, 4)
#	set_global_scale(Vector2(scale, scale)) 

func _on_Health_body_entered(body):
	if body is KinematicBody2D and can_heal:
		GameInfo.heal_player(heal_amount)
		queue_free()


func _on_SpawnTime_timeout():
	$AnimationPlayer.play("Fade")
	can_heal = true
