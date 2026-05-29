extends Area2D

func reset_player(player):
	player.position = Vector2(640,360)
	player.scale = Vector2(3.0,3.0)
	player.modulate = Color(1,1,1,1)
	player.sprite.offset.y = 20.0
	var spawn_tween = get_tree().create_tween().set_parallel(true)
	spawn_tween.tween_property(player,"scale", Vector2(1.0,1.0),3)\
	.set_trans(Tween.TRANS_EXPO)
	spawn_tween.tween_property(player.sprite,"offset:y", 0,3)
	
	await spawn_tween.finished
	player.movement = true

func fall_animation(player):
	var fall_tween = get_tree().create_tween().set_parallel(true)
	fall_tween.tween_property(player, "scale", Vector2(0.0,0.0),0.5)\
		.set_trans(Tween.TRANS_QUAD)\
		.set_ease(Tween.EASE_IN)
	fall_tween.tween_property(player,"modulate", Color(0.7,0.7,0.7,1),0.5)
	
	await fall_tween.finished
	reset_player(player)
func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		body.velocity = Vector2.ZERO
		body.movement = false
		fall_animation(body)
