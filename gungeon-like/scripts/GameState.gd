extends Node

var player_health := 4:
	set(new_value):
		player_health = new_value
		if player_health <= 0:
			trigger_death()
var current_enemies = 0

func reset_globals():
	player_health = 4
	current_enemies = 0

func trigger_death():
	print("Game Over!")
	get_tree().quit()
