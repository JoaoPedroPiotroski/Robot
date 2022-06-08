extends KinematicBody2D

var move_direction = 1

var health = 1

var velocity = Vector2.ZERO

var invulnerable = true

func _ready():
	$Sprite.flip_h = move_direction > 0

func _physics_process(delta):
	
	$Sprite.flip_h = velocity.x > 0
	
	velocity = velocity.move_toward(Vector2(move_direction * 400, 0), 500 * delta)
	
	velocity = move_and_slide(velocity)
	
	if velocity == Vector2.ZERO:
		queue_free()
	


#	for detector in $WallDetector.get_children():
#		if detector.is_colliding():
#			queue_free()
	


func _on_Lifetime_timeout():
	queue_free()

func damage(amount):
	health -= amount
	if health <= 0:
		die()
		
func die():
	queue_free()

func _on_Hurtbox_area_entered(area):
	if area.get_parent().velocity.y >= 0 or velocity.y < 0 and !invulnerable:
		damage(1)
		GameInfo.make_player_jump(true)
		GameInfo.player_jump_height = 600


func _on_SpawnTime_timeout():
	invulnerable = false



func _on_HitBox_area_entered(area):
	die()
