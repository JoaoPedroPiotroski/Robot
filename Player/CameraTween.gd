extends Tween

onready var parent = get_parent()

func change_camera_pos(_start, x, y, time):
	var _a = interpolate_property(parent,
	"position",
	null,
	Vector2(x, y),
	time,
	Tween.TRANS_SINE,
	Tween.EASE_OUT)
	var _b = start()
