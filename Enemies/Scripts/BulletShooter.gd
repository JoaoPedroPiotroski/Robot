extends StaticBody2D

export var direction : int = 1
export var player_deactivatable : bool = true

var children_amount
var distance_to_player = 200

func _ready():
	children_amount = get_child_count()
	$Sprite.flip_h = direction > 0
	
func _on_ShootTime_timeout():
	
	if $PlayerDetector.player != null:
		distance_to_player = global_position.distance_to($PlayerDetector.player.global_position)
		
	if !player_deactivatable:
		distance_to_player = 1000
	
	if get_child_count() < children_amount + 3 and (distance_to_player > 100):
		var scene = load("res://Enemies/Bullet.tscn")
		var bullet = scene.instance()
		add_child(bullet)
		bullet.global_position = self.global_position + Vector2(direction * 32, 0)
		bullet.move_direction = direction
