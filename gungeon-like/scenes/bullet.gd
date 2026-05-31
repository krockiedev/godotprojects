extends Area2D

@export var SPEED : float = 2000
@export var direction: Vector2 = Vector2.LEFT
@onready var sprite: Sprite2D = $Sprite2D
@export var angle: float

func _physics_process(delta: float) -> void:
	position += direction.normalized() * SPEED * delta
	
	pass
func _ready() -> void:
	sprite.rotation = angle
	
func screen_exitted() -> void:
	var tween_out = get_tree().create_tween()
	tween_out.tween_property(self, "modulate", Color(1,1,1,0),0.5)\
	.set_trans(Tween.TRANS_LINEAR)
	await tween_out.finished
	
	queue_free()
