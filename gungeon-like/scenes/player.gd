extends CharacterBody2D
@onready var sprite: Sprite2D = $Sprite2D
@onready var crosshair: AnimatedSprite2D = $UI/Crosshair

var movement = true
@export var can_shoot = true
const SPEED = 300.0

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			if can_shoot:
				shoot()
			else:
				blank()

func shoot():
	var crosshair_tween
	crosshair.play("shoot")
	
	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()
		
	crosshair.scale = Vector2.ONE
	crosshair.rotation = 0.0
	crosshair_tween = get_tree().create_tween()
	crosshair_tween.set_parallel(true)
	
	var random_spin := randf_range(-0.2, 0.2)
	
	crosshair_tween.tween_property(crosshair, "scale", Vector2(1.5, 1.5), 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	crosshair_tween.tween_property(crosshair, "rotation", random_spin, 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	crosshair_tween.chain().tween_property(crosshair, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT) # TRANS_BACK adds a tiny bounce!
	crosshair_tween.parallel().tween_property(crosshair, "rotation", 0.0, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

func blank():
	var crosshair_tween
	
	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()
		
	crosshair.scale = Vector2.ONE
	crosshair.rotation = 0.0
	crosshair_tween = get_tree().create_tween()
	
	var random_spin := randf_range(-0.2, 0.2)
	crosshair_tween.tween_property(crosshair, "rotation", random_spin, 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	crosshair_tween.tween_property(crosshair, "rotation", 0.0, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func _physics_process(delta: float) -> void:
	if movement:
		var direction := Input.get_vector("left", "right", "up", "down")
		if direction:
			velocity = direction * SPEED
		else:
			velocity = velocity.move_toward(Vector2.ZERO, SPEED)
	
	crosshair.global_position = crosshair.get_global_mouse_position()
	move_and_slide()
