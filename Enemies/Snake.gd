extends KinematicBody2D

export var max_speed : float = 75
export var acceleration : float = 150
export var health : int = 1

var move_direction : float = 1
var velocity : Vector2 = Vector2.ZERO

onready var right_ground = $GroundDetectors.get_node("Right/GroundDetectorRight")
onready var left_ground = $GroundDetectors.get_node("Left/GroundDetectorLeft")
onready var wall_detectors = $WallDetectors

func is_there_wall():
	for detector in wall_detectors.get_children():
		if detector.is_colliding():
			if detector.name == "WallDetectorLeft":
				move_direction = 1
			elif detector.name == "WallDetectorRight":
				move_direction = -1

func is_inverse(num1, num2):
	if (num1 < 0 and num2 > 0) or (num1 > 0 and num2 < 0):
		return true
	return false

func is_there_ground():
	if left_ground.is_colliding() == false:
		return 1
	elif right_ground.is_colliding() == false:
		return -1
	return move_direction

func _physics_process(delta):
	if velocity.x < 0:
		$AnimationPlayer.play_backwards("default")
	else:
		$AnimationPlayer.play("default")
	#var old_dir = move_direction
	move_direction = is_there_ground()
	is_there_wall()
	if is_inverse(move_direction, velocity.x):
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * delta * 50).x
	else:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * delta).x
	velocity.y = velocity.move_toward(Vector2(0, 1 * 50 * max_speed), acceleration * 4 * delta).y
	velocity = move_and_slide(velocity)

func die():
	queue_free()

func damage(amount):
	health -= amount
	if health <= 0:
		die()

func _on_Hurtbox_area_entered(area):
	if area.get_parent().velocity.y > 0 or velocity.y < 0:
		damage(1)
		GameInfo.should_player_jump = true
