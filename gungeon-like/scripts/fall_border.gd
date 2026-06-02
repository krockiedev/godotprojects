@tool
extends Area2D

enum HazardType {FALL, LAVA, SPIKE}

@export var hazard: HazardType = HazardType.FALL

@export var zone_size: Vector2 = Vector2(64, 64):
	set(value):
		zone_size = value
		update_collision_shape()

@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var lava_timer: Timer = $LavaTimer

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

func fall_player(body):
	body.velocity = Vector2.ZERO
	body.movement = false
	fall_animation(body)
	GameState.player_health -= 1

func lava_player(body):
	if lava_timer.is_stopped():
		lava_timer.start()

func _on_body_entered(foot: Area2D) -> void:
	if Engine.is_editor_hint(): return
	var body = foot.get_parent()
	
	if body and body.is_in_group("player"):
		match hazard:
			HazardType.FALL:
				fall_player(body)
			HazardType.LAVA:
				lava_player(body)
			HazardType.SPIKE:
				fall_player(body)



func _on_body_exited(foot: Area2D) -> void:
	if Engine.is_editor_hint(): return
	var body = foot.get_parent()
	
	if body and body.is_in_group("player"):
		match hazard:
			HazardType.FALL:
				fall_player(body)
			HazardType.LAVA:
				lava_timer.stop()
			HazardType.SPIKE:
				fall_player(body)
	
func lava_burn() -> void:
	GameState.player_health -= 1
