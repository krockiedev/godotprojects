extends CharacterBody2D
@onready var sprite: Sprite2D = $Sprite2D

var movement = true
const SPEED = 300.0

func _physics_process(delta: float) -> void:
	if movement:
		var direction := Input.get_vector("left", "right", "up", "down")
		if direction:
			velocity = direction * SPEED
		else:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	
	move_and_slide()
