extends KinematicBody2D

onready var bullet_spawn_point = $GunPivot/BulletSpawn
onready var left_positions = get_parent().get_node("LeftPositions").get_children()
onready var right_positions = get_parent().get_node("RightPositions").get_children()
onready var crazy_positions = get_parent().get_node("CrazyPositions").get_children()
onready var idle_timer = $Idle
onready var animation_player = $AnimationPlayer
onready var crazy_teleport_timer = $CrazyTeleport
onready var ui = get_parent().get_parent().get_node("CanvasLayer/UI")

signal boss_died

enum {
	attacking,
	idle,
	special,
	crazy,
	teleporting
} 

var state = idle

var invincibility_frames = 1.0

var health = 15
var crazy_started = false
var current_position = null
var fight_started = false
var x_direction = 1
var crazy_teleport_count = 0
var is_crazy_teleporting = false
var crazy_animation_direction = "left"
var attack_times = 0
var can_crazy_teleport = true
var previous_state = attacking
var is_crazy_attacking = false
var is_teleporting_to_center = false

func _ready():
# warning-ignore:return_value_discarded
	get_parent().get_node("BossArenaEntered").connect("arena_entered", self, "start_fight")
	
func start_fight():
	ui.get_node("BossHealthBar").visible = true
	ui.get_node("BossHealthBar/BossHealth").rect_size = Vector2(12 * health, 6) 
	animation_player.play("fight_start")
	fight_started = true
	idle_timer.start()
	
func teleport():
	global_position = current_position.global_position
	
func teleport_to_position():
	state = teleporting
	animation_player.play("teleport")

func teleport_ended():
	is_teleporting_to_center = false
	if previous_state == crazy:
		state = crazy
		crazy_teleport_timer.start(0.2)
		can_crazy_teleport = true

	if previous_state == attacking:
		state = attacking
		
		if x_direction > 0:
			animation_player.play("3_shot_right")
		else:
			animation_player.play("3_shot_left")

func get_new_position():
	left_positions.shuffle()
	right_positions.shuffle()
	crazy_positions.shuffle()
	
	if !is_crazy_attacking:
		if randi() % 100 > 50:
			x_direction = 1
			if left_positions[0] != current_position:
				current_position = left_positions[0]
			else:
				get_new_position()
		else:
			x_direction = -1
			if right_positions[0] != current_position:
				current_position = right_positions[0]
			else:
				get_new_position()
	else:
		if crazy_positions[0] != current_position:
			current_position = crazy_positions[0]
		else:
			get_new_position()
	
func attacking_state():
	previous_state = attacking
	
func go_to_idle_state():
	state = idle
	idle_timer.start(1)
	if randi() %100 < 10: 
		crazy_started = false
		state = crazy
		crazy_teleport_count = int(rand_range(1, 6))
		attack_times = int(rand_range(2, 4))
		is_crazy_teleporting = true
		animation_player.play("crazy_start")

func start_crazy():
	crazy_started = true
	
func idle_state():
	animation_player.play("idle") 
	if idle_timer.time_left <= 0:
		state = attacking
		get_new_position()
		teleport_to_position()
	
func special_state():
	pass
	
func crazy_state():
	if !crazy_started:
		return
	previous_state = crazy
	if crazy_teleport_timer.time_left <= 0 and can_crazy_teleport and crazy_teleport_count > 0 and is_crazy_teleporting:
		get_new_position()
		can_crazy_teleport = false
		teleport_to_position()
		crazy_teleport_count -= 1
	if crazy_teleport_count <= 0 and is_crazy_teleporting:
		is_crazy_attacking = true
		get_new_position()
		teleport_to_position()
		is_crazy_teleporting = false
		attack_times = int(rand_range(2, 4))
		crazy_teleport_count = int(rand_range(1, 6))
		is_teleporting_to_center = true
	state = crazy
	if !is_teleporting_to_center and !is_crazy_teleporting and animation_player.current_animation != "crazy_shot_" + crazy_animation_direction and attack_times > 0:
		animation_player.play("crazy_shot_" + crazy_animation_direction)
		is_crazy_attacking = true
		attack_times -= 1
	if attack_times <= 0 and !is_crazy_teleporting:
		is_crazy_attacking = false
		is_crazy_teleporting = true
		attack_times = int(rand_range(2, 4))
		state = attacking
		get_new_position()
		teleport_to_position()
		
func change_crazy_direction(direction : String):
	crazy_animation_direction = direction

func _physics_process(delta):
	if !fight_started:
		return
	match state:
		attacking:
			attacking_state()
		idle:
			idle_state()
		special:
			special_state()
		crazy:
			crazy_state()
	invincibility_frames -= delta
	
func shoot():
	var scene = load("res://World/Levels/Level2/BossBullet.tscn")
	var bullet = scene.instance()
	bullet.global_position = bullet_spawn_point.global_position #+ ( bullet_spawn_point.global_position - global_position * 61 )
	bullet.move_direction = global_position.direction_to(bullet_spawn_point.global_position)
	get_parent().get_node("Bullets").add_child(bullet)

func die():
	emit_signal("boss_died")
	ui.get_node("BossHealthBar").visible = false
	queue_free()

func damage(amount):
	if invincibility_frames <= 0:
		invincibility_frames = 1
		health -= amount
	ui.get_node("BossHealthBar/BossHealth").rect_size = Vector2(12 * health, 6) 
	if health <= 0:
		die()

func _on_Hurtbox_area_entered(area):
	if area.get_parent().velocity.y >= 0:
		damage(area.damage)
	GameInfo.should_player_jump = true
	GameInfo.player_jump_height = 800
	get_new_position()
	teleport_to_position()
