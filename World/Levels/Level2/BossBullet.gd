extends KinematicBody2D

var move_direction : Vector2 = Vector2.ZERO
var velocity : Vector2 = Vector2.ZERO

export var max_speed = 300
export var acceleration = 300
var look_toward

func _ready():
	look_toward = global_position + move_direction
	if look_toward.x < 0:
		look_toward.y = - look_toward.y

func _physics_process(delta):

	look_at(look_toward)
	
	velocity = velocity.move_toward(move_direction * max_speed, acceleration * delta)
	
# warning-ignore:return_value_discarded
	move_and_collide(velocity * delta)

func die():
	queue_free()

func _on_Hurtbox_area_entered(area):

	if area.get_parent() is StaticBody2D:
		die()
	else:
		if area.get_parent().velocity.y >= 0 or velocity.y < 0 and area.get_parent() is KinematicBody2D:
			GameInfo.should_player_jump = true
			GameInfo.player_jump_height = 350
			die()


func _on_Lifetime_timeout():
	die()
