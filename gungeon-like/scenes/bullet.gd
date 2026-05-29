extends Area2D

@export var SPEED : float = 1000
@export var direction: Vector2 = Vector2.LEFT

func _physics_process(delta: float) -> void:
	position += direction.normalized() * SPEED * delta

func screen_exitted() -> void:
	print("Vat da Helly")
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(self, "modulate", Color(1,1,1,0),0.5)\
	.set_trans(Tween.TRANS_LINEAR)
	await tween_out.finished
	
	queue_free()
