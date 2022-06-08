extends Camera2D

export var walking_transform = 150
export var falling_transform = 100
export var wall_transform = 150
export var wall_jump_transform = 200
#
var old_goal : Vector2
var new_goal : Vector2
var tweening_timer : float = 0.2
var old_pos : Vector2#var time = 1
#
enum {
	walk,
	ascent,
	descent,
	wall_sliding,
	wall_jumping,
	dashing
}

onready var parent = get_parent()
onready var shape = $Camera/Shape
onready var tween = $CameraTween

func _physics_process(_delta):
	shape.shape.extents = get_viewport_rect().size

func _process(_delta):
	drag_margin_v_enabled = !parent.is_colliding_with_ground()
	shape.shape.extents = get_viewport_rect().size
	offset_h = parent.velocity.x / parent.max_speed * 3.5
	offset_v = (-int(Input.is_action_pressed("up")) * 2) + int(Input.is_action_pressed("down"))
	offset_h = !parent.state == dashing
