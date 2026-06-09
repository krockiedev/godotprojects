extends MeshInstance3D

const BULLET = preload("uid://3tucrctc3pd6")
var playernode

func _ready() -> void:
	playernode = get_tree().get_first_node_in_group("player")

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if playernode and playernode.can_shoot:
				var map_node = get_tree().get_first_node_in_group("bullets")
				if not map_node: return # Safety check
				
				var bullet_instance = BULLET.instantiate()
				
				# 1. Get the direction the gun is facing (-Z is forward in Godot 3D)
				var bullet_direction = -global_transform.basis.z.normalized()
				
				# 2. Pass the 3D direction vector and rotation transform to the bullet
				bullet_instance.direction = bullet_direction
				bullet_instance.global_transform = global_transform 
				# 3. Spawn the bullet exactly at the gun's position instead of the player's center
				bullet_instance.global_position = global_position
				
				map_node.add_child(bullet_instance)
				playernode.shoot()
			else:
				if playernode:
					playernode.blank()
