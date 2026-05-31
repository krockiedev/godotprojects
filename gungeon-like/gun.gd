extends Node2D

const BULLET = preload("uid://k8vfwj2jmo27")

var playernode

func _ready() -> void:
	playernode = get_parent()

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if playernode.can_shoot:
				var map_node = get_tree().get_first_node_in_group("bullets")
				var bullet_instance = BULLET.instantiate()
				
				var mouse_pos = get_global_mouse_position()
				var gun_pos = global_position
				
				var delta_x = mouse_pos.x - gun_pos.x
				var delta_y = mouse_pos.y - gun_pos.y
				
				var angle = atan2(delta_y, delta_x)
				
				bullet_instance.direction = Vector2(cos(angle), sin(angle))
				bullet_instance.angle = angle
				bullet_instance.position = playernode.position
				map_node.add_child(bullet_instance)
				playernode.shoot()
			else:
				playernode.blank()
