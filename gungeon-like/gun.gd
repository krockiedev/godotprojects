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
				bullet_instance.direction = Vector2(0.2,0.4)
				bullet_instance.position = playernode.position
				map_node.add_child(bullet_instance)
				print("YOYOYO")
				playernode.shoot()
			else:
				playernode.blank()
