@tool
extends Area2D

@export var zone_size: Vector2 = Vector2(64, 64):
	set(value):
		zone_size = value
		update_collision_shape()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	update_collision_shape()

func update_collision_shape() -> void:
	if not is_inside_tree() or not has_node("CollisionShape2D"): 
		return
		
	var shape_node = $CollisionShape2D

	if not shape_node.shape is RectangleShape2D:
		shape_node.shape = RectangleShape2D.new()
	else:
		shape_node.shape = shape_node.shape.duplicate()

	shape_node.shape.size = zone_size

func reset_player(player):
	if Engine.is_editor_hint(): return 
	
	player.position = Vector2(640, 360)
	player.scale = Vector2(3.0, 3.0)
	player.modulate = Color(1, 1, 1, 1)
	player.sprite.offset.y = 20.0
	var spawn_tween = get_tree().create_tween().set_parallel(true)
	spawn_tween.tween_property(player, "scale", Vector2(1.0, 1.0), 3)\
		.set_trans(Tween.TRANS_EXPO)
	spawn_tween.tween_property(player.sprite, "offset:y", 0, 3)
	
	await spawn_tween.finished
	player.movement = true

func fall_animation(player):
	if Engine.is_editor_hint(): return
	
	var fall_tween = get_tree().create_tween().set_parallel(true)
	fall_tween.tween_property(player, "scale", Vector2(0.0, 0.0), 0.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	fall_tween.tween_property(player, "modulate", Color(0.7, 0.7, 0.7, 1), 0.5)
	
	await fall_tween.finished
	reset_player(player)

func _on_body_entered(foot: Area2D) -> void:
	if Engine.is_editor_hint(): return
	print("Entered")
	var body = foot.get_parent()
	
	if body and body.is_in_group("player"):
		body.velocity = Vector2.ZERO
		body.movement = false
		fall_animation(body)
