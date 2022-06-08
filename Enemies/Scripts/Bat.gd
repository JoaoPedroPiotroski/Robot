extends KinematicBody2D

export var max_speed : float = 250
export var acceleration : float = 200
export var decceleration : float = 75
export var max_distance_to_target : float = 4
export var health = 1

var velocity : Vector2 = Vector2.ZERO
var target : Vector2 = Vector2.ZERO
var start_position : Vector2
var update_direction_timer : float = 0
var player_direction = Vector2.ZERO

enum {
	idle,
	wander,
	chase
}
var state = idle

onready var player_detector = $PlayerDetector
onready var wander_timer = $WanderTimer
onready var ground_detector = $GroundDetector

func _ready():
	start_position = global_position
	
func get_new_target():
	target = start_position + Vector2(rand_range(-64, 64), rand_range(-32, 32))

func pick_random_state(state_list):
	state_list.shuffle()
	return state_list.pop_front()

func is_near_ground():
	if ground_detector.is_colliding():
		return true
	return false

func update_wander_timer():
	if wander_timer.time_left <= 0:
		var old = state
		state = pick_random_state([idle, wander])
		if state != old and state == wander:
			get_new_target()
		wander_timer.start(rand_range(1, 3)) 

func seek_player():
	if player_detector.can_see_player():
		state = chase

func idle_state():
	state = chase
	get_new_target()
	seek_player()
	update_wander_timer()
	velocity = velocity.move_toward(Vector2.ZERO, decceleration)
	
func wander_state(delta):
	if is_near_ground():
		target.y -= 50
	seek_player()
	update_wander_timer()
	var direction = global_position.direction_to(target)
	velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	
	if global_position.distance_to(target) <= max_distance_to_target:
		state = pick_random_state([idle, wander])
	
func chase_state(delta):
	var player = player_detector.player
	if update_direction_timer <= 0 and player != null:
		if GameInfo.is_player_grounded or GameInfo.is_player_on_wall:
			player_direction = global_position.direction_to(player.global_position)
		else:
			wander_state(delta)
		update_direction_timer = 0.5
	if player != null:
		var direction = player_direction
		velocity = velocity.move_toward(direction * max_speed, acceleration * delta)
	else:
		state = wander
	update_direction_timer -= delta

func _physics_process(delta):
	match (state):
		idle:
			idle_state()
		wander:
			wander_state(delta)
		chase:
			chase_state(delta)
			
	velocity = move_and_slide(velocity)
	
func die():
	
	if int(rand_range(1, 5)) == 4:
		var scene = load("res://World/Recurring/Health.tscn")
		var health = scene.instance()
		health.heal_amount = int(rand_range(1, 3))
		health.global_position = Vector2(global_position.x, global_position.y - 50)
		get_parent().get_parent().add_child(health)
	
	queue_free()
	
func damage(amount):
	health -= amount
	if health <= 0:
		die()

func _on_Hurtbox_area_entered(area):
	if area.get_parent() is KinematicBody2D:
		if area.get_parent().velocity.y > 0 or velocity.y < 0:
			damage(1)
			GameInfo.make_player_jump(true)
			GameInfo.player_jump_height = 800
