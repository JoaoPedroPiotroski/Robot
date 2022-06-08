extends Node

var start_pos : Vector2 = Vector2.ZERO
var is_player_grounded : bool = false
var is_player_on_wall : bool = false
var should_player_jump : bool = false
var amount_player_should_heal : int = 0
var player_jump_height = 950
var is_new_level = true
var score = 0

var go_portal = ""

func update_player_grounded(is_it):
	is_player_grounded = is_it
	
func update_player_on_wall(is_it):
	is_player_on_wall = is_it

func make_player_jump(is_it):
	should_player_jump = is_it
	
func heal_player(amount):
	amount_player_should_heal = amount
	
