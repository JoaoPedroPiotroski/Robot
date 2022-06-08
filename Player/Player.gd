extends KinematicBody2D

export var max_speed : float = 250
export var acceleration : float  = 750
export var decceleration : float = 1500
export var gravity : float  = 44 * 70
export var terminal_velocity : float = 250
export var jump_power : float = 950
export var max_health : int = 5
export var dash_speed : float = 700

var anim_direction : Vector2 = Vector2.ZERO
var can_dash = true
var move_direction : float = 0
var dash_direction : float = 1
var velocity : Vector2 = Vector2.ZERO
var snap : Vector2 = Vector2.ZERO
var is_jumping : bool = false
var wall_direction : float = 0
var can_double_jump : bool = true
var active_effects : Array = []
var turning : bool = false
var last_animation : String = ""
var jump_timer : float = 0
var ground_timer : float = 0

enum {
	walk,
	ascent,
	descent,
	wall_sliding,
	wall_jumping,
	dashing
}

var state = walk

onready var health = max_health

onready var animation_tree = $AnimationTree
onready var animation_state = animation_tree.get("parameters/playback")
onready var hit_flash = $HitFlash

onready var ground_detectors = $GroundDetectors.get_children()
onready var wall_detectors = $WallDetectors
onready var left_wall
onready var right_wall

onready var ui = get_parent().get_node("CanvasLayer/UI")

onready var jump_particles = $Smoke
onready var slide_particles_left = $SlidingParticlesLeft
onready var slide_particles_right = $SlidingParticlesRight
onready var walking_particles = $WalkingParticles
onready var ghost_spawner = $GhostSpawner

onready var available_effects : Array = [
	walking_particles,
	jump_particles,
	slide_particles_left,
	slide_particles_right,
	ghost_spawner
]

func make_effects():
	for effect in available_effects:
		if effect in active_effects:
			if effect is Particles2D:
				effect.emitting = true
			elif effect is Node2D:
				effect.active = true
		else:
			if effect is Particles2D:
				effect.emitting = false
			elif effect is Node2D:
				effect.active = false
				
func deactivate_effect(effects : Array):
	for effect in effects:
		if effect in active_effects:
			active_effects.erase(effect)
		
func activate_effect(effects : Array):
	for effect in effects:
		if !(effect in active_effects):
			active_effects.append(effect)

func animate():
	var frame_animation = "Walk"
	
	if move_direction != 0 and state != dashing:
		dash_direction = move_direction
		anim_direction.x = move_direction
	match (state):
		walk:
			
			frame_animation = "Walk"
			
			if is_inverse(velocity.x, move_direction):
				frame_animation = "Turning"
				turning = true
			elif turning and (velocity.x < 100 and velocity.x > -100):
				frame_animation = "Turning"
				turning = true
			else:
				frame_animation = "Walk"
				turning = false
			
			if velocity.x == 0:
				frame_animation = "Idle"
			
		ascent:
			frame_animation = "Ascent"
		descent:
			frame_animation = "Descent"
		wall_sliding:
			anim_direction.x = -wall_direction
			frame_animation = "WallSlide"
		wall_jumping:
			frame_animation = "WallJump"
		dashing:
			frame_animation = "Dash"
			animation_state.travel("Dash")
			
	if frame_animation != last_animation:
		animation_state.travel(frame_animation)	
		last_animation = frame_animation
		
	# just blend position updates
	
	animation_tree.set("parameters/Walk/blend_position", anim_direction)
	animation_tree.set("parameters/Descent/blend_position", anim_direction)
	animation_tree.set("parameters/WallSlide/blend_position", anim_direction)
	animation_tree.set("parameters/WallJump/blend_position", anim_direction)
	animation_tree.set("parameters/Ascent/blend_position", anim_direction)
	animation_tree.set("parameters/Dash/blend_position", Vector2(dash_direction, 0))
	animation_tree.set("parameters/Idle/blend_position", anim_direction)
	animation_tree.set("parameters/Turning/blend_position", anim_direction)

func _ready():
	if !GameInfo.is_new_level:
		global_position = GameInfo.start_pos
	$Camera2D.current = true
	animation_tree.active = true
	ui.get_node("EmptyHeart").rect_size = Vector2(32 * max_health, 32) 
	ui.get_node("FullHeart").rect_size = Vector2(32  * health, 32)
	
func is_with_wall():
	for half in wall_detectors.get_children():
		for detector in half.get_children():
			if detector.is_colliding():
				return true
	deactivate_effect([slide_particles_left, slide_particles_right])
	return false
	
func is_wall_on_left():
	for detector in wall_detectors.get_node("Left").get_children():
		if detector.is_colliding():
			return true
	return false
	
func is_wall_on_right():
	for detector in wall_detectors.get_node("Right").get_children():
		if detector.is_colliding():
			return true
	return false
	
func get_wall_direction():
	if is_wall_on_left():
		active_effects = [slide_particles_left]
		wall_direction = -1
	if is_wall_on_right():
		wall_direction = 1
		active_effects = [slide_particles_right]
	if is_wall_on_left() and is_wall_on_right() and move_direction != 0:
		wall_direction = move_direction
		if move_direction == 1:
			active_effects = [slide_particles_right]
		else:
			active_effects = [slide_particles_left]

func is_on_ground():
	for detector in ground_detectors:
		if detector.is_colliding():
			ground_timer = 0.2
	if ground_timer > 0:
		return true
	return false
	
func is_colliding_with_ground(): 
	for detector in ground_detectors:
		if detector.is_colliding():
			return true
	return false
	
func take_input():
	move_direction = -int(Input.is_action_pressed("left")) + int(Input.is_action_pressed("right"))
	
func move():
	snap = Vector2(0, 50)
	if is_jumping:
		snap = Vector2.ZERO
	velocity = move_and_slide_with_snap(velocity, Vector2(0, -1), Vector2(0, 32 * 2)) 
	
func apply_gravity(delta, multiplier : float = 1.0):
	velocity.y = velocity.move_toward(Vector2(0, terminal_velocity * multiplier), gravity * multiplier * delta).y
	
func is_inverse(num1, num2): # Returns true if one number is negative and the other is positive, returns false in any other case
	if (num1 < 0 and num2 > 0) or (num1 > 0 and num2 < 0):
		return true
	return false
	
func jump():
	activate_effect([ghost_spawner, jump_particles])
	deactivate_effect([walking_particles])
	jump_timer = 0
	velocity.y = -jump_power
	state = ascent
	can_double_jump = true
	is_jumping = true
	
func walk_state(delta):
	can_dash = true
	
	if velocity.x != 0:
		activate_effect([walking_particles])
	else:
		deactivate_effect([walking_particles])
	
	take_input()

	velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * delta).x
	if is_inverse(move_direction, velocity.x) or move_direction == 0:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), decceleration * delta).x
	
	apply_gravity(delta)
	
	if jump_timer > 0 and is_on_ground():
		jump()
		
	if Input.is_action_just_pressed("dash"):
		can_dash = false
		deactivate_effect([walking_particles])
		state = dashing
	
	# Updates the direction of the walking dust particles
	if move_direction != -1:
		walking_particles.set_global_rotation_degrees(180)
		walking_particles.process_material.direction.y = 0.3
	else:
		walking_particles.set_global_rotation_degrees(0)
		walking_particles.process_material.direction.y = -0.3
	
	move()
		
	if velocity.y > 0 and is_on_ground() == false:
		state = descent
		deactivate_effect([walking_particles])
	
func ascent_state(delta):
	
	take_input()

	velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * 2 * delta).x
	if is_inverse(move_direction, velocity.x) or move_direction == 0:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), decceleration * 3 * delta).x
	
	apply_gravity(delta)
	
	if velocity.y > 0:
		state = descent
		is_jumping = false
		
	if velocity.y > -jump_power + 500:
		deactivate_effect([ghost_spawner])
		
	if Input.is_action_just_released("jump"):
		velocity.y *= 0.4
		
	if Input.is_action_just_pressed("dash"):
		deactivate_effect([jump_particles])
		can_dash = false
		state = dashing
		
	# Double jumping Hijinks
	if Input.is_action_just_pressed("jump") and can_double_jump:
		activate_effect([jump_particles, ghost_spawner])
		velocity.y = -jump_power * 0.9
		state = ascent
		is_jumping = true
		can_double_jump = false
		
	if is_with_wall():
		velocity = Vector2.ZERO
		state = wall_sliding
	
	move()
	
func descent_state(delta):
	take_input()

	deactivate_effect([jump_particles])

	velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * 2 * delta).x
	if is_inverse(move_direction, velocity.x) or move_direction == 0:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), decceleration * 3 * delta).x
	
	apply_gravity(delta, 1.8)

	deactivate_effect([ghost_spawner])
	if velocity.y >= 420:
		activate_effect([ghost_spawner])
	
	if Input.is_action_just_pressed("jump") and can_double_jump:
		activate_effect([ghost_spawner, jump_particles])
		velocity.y = -jump_power * 0.9
		state = ascent
		is_jumping = true
		can_double_jump = false
		
	if Input.is_action_just_pressed("dash") and can_dash:
		can_dash = false
		state = dashing
	
	if is_on_ground():
		state = walk
		deactivate_effect([ghost_spawner])
		
	if is_with_wall():
		state = wall_sliding
		deactivate_effect([ghost_spawner])
		velocity *= 0.1
	
	move()
	
func wall_sliding_state(delta):
	
	can_double_jump = true
	
	take_input()
	
	get_wall_direction()
	dash_direction = -wall_direction
	
	deactivate_effect([jump_particles, ghost_spawner])
	
	velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * delta).x

	if !is_with_wall():
		deactivate_effect([slide_particles_left, slide_particles_right])
		state = ascent
		if velocity.y > 0:
			state = descent
	
	if velocity.y > 0 and !Input.is_action_pressed("down"):
		apply_gravity(delta, 0.40)
	else:
		apply_gravity(delta, 0.90)
	
	if is_on_ground():
		deactivate_effect([slide_particles_left, slide_particles_right])
		state = walk
		
	if is_with_wall() and jump_timer > 0:
		if is_wall_on_left() and is_wall_on_right():
			velocity.y = -jump_power * 0.8
		else:
			velocity.y = -jump_power
		deactivate_effect([slide_particles_left, slide_particles_right])
		activate_effect([jump_particles])
		is_jumping = true
		get_wall_direction()
		velocity.x = -wall_direction * 400
		if wall_direction == 1:
			velocity.x = -wall_direction * 600
		state = wall_jumping
		
	if Input.is_action_just_pressed("dash"):
		can_dash = false
		deactivate_effect([slide_particles_left, slide_particles_right])
		state = dashing
	
	move()
	
func wall_jumping_state(delta):
	take_input()

	if move_direction == 0:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), decceleration * delta).x
	elif is_inverse(move_direction, velocity.x) and move_direction != 0:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), decceleration * 5 * delta).x
	else:
		velocity.x = velocity.move_toward(Vector2(move_direction * max_speed, 0), acceleration * 2 * delta).x
	
	apply_gravity(delta)
	
	if Input.is_action_just_released("jump"):
		deactivate_effect([ghost_spawner])
		velocity.y *= 0.6
		state = descent
		
	if Input.is_action_just_pressed("jump") and can_double_jump:
		activate_effect([jump_particles, ghost_spawner])
		velocity.y = -jump_power * 0.9
		state = ascent
		is_jumping = true
		can_double_jump = false
		
	if Input.is_action_just_pressed("dash") and can_dash:
		can_dash = false
		state = dashing
	
	if is_on_ground():
		deactivate_effect([ghost_spawner])
		state = walk
		
	if velocity.y > 0:
		deactivate_effect([ghost_spawner])
		state = descent
		
	if is_with_wall():
		velocity *= 0.1
		deactivate_effect([ghost_spawner])
		state = wall_sliding
	
	move()

func dashing_state(delta):
	activate_effect([ghost_spawner])
	velocity.y = 0
	velocity.x = velocity.move_toward(Vector2(dash_direction * dash_speed, 0), acceleration * 8 * delta).x
	
	velocity = move_and_slide_with_snap(velocity, Vector2(0, 0))

func heal(amount):
	if health + amount < max_health:
		health += amount
	elif health + amount >= max_health:
		health = max_health

func _physics_process(delta):
	ground_timer -= delta
	jump_timer -= delta
	match (state):
		walk:
			walk_state(delta)
		ascent:
			ascent_state(delta)
		descent:
			descent_state(delta)
		wall_sliding:
			wall_sliding_state(delta)
		wall_jumping:
			wall_jumping_state(delta)
		dashing:
			dashing_state(delta)
			
	make_effects()
	take_input()
	animate()
	
	if Input.is_action_just_pressed("jump"):
		jump_timer = 0.2
		
	GameInfo.update_player_grounded(is_on_ground())
	GameInfo.update_player_on_wall(is_with_wall())
	
	if state != dashing:
		$RocketFire2.emitting = false
		$RocketFire3.emitting = false
	
	if GameInfo.should_player_jump:
		activate_effect([ghost_spawner])
		if GameInfo.player_jump_height != jump_power:
			velocity.y = -GameInfo.player_jump_height
			GameInfo.player_jump_height = jump_power
		else:
			velocity.y = -jump_power * 0.95
		can_double_jump = true
		state = ascent
		GameInfo.make_player_jump(false)

func _process(_delta):
	heal(GameInfo.amount_player_should_heal)
	GameInfo.amount_player_should_heal = 0
	update_health()
	
func update_health():
	ui.get_node("FullHeart").rect_size = Vector2(32  * health, 32)
	
func kill():
	get_tree().reload_current_scene()
	global_position = GameInfo.start_pos
	health = max_health
	update_health()
	
func damage(amount):
	health -= amount
	update_health()
	if health <= 0:
		kill()

func _on_Hurtbox_area_entered(area):
	if $InvicibilityTimer.time_left <= 0:
		
		hit_flash.play("HitFlash")
		if velocity.y >= 0:
			velocity = Vector2(-anim_direction.x, velocity.y) * 250
		else:
			velocity = Vector2(-anim_direction.x, -velocity.y)
		
		if velocity.y == 0:
			velocity.y = -150
			
		$InvicibilityTimer.start(0.6)
	
		damage(area.damage)

func dash_end():
	velocity *= 0.88
	deactivate_effect([ghost_spawner])
	state = descent
	$DashCooldown.start(0.8)

func _on_DashCooldown_timeout():
	can_dash = true
