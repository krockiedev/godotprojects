extends CharacterBody2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var crosshair: AnimatedSprite2D = $UI/Crosshair
@onready var hitbox: CollisionShape2D = $CollisionShape2D

enum State {NORMAL, DODGING}
var movement = true
@export var can_shoot = true
const SPEED = 300.0
const DODGE_SPEED = 500.0
const DODGE_DURATION = 0.35

@onready var dodge_timer: Timer = $Dodge

var current_state: State = State.NORMAL
var roll_direction := Vector2.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	dodge_timer.timeout.connect(on_dodge_finished)

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
	if hitbox.disabled:
		sprite.modulate = Color(0.5,1,0.5,0.5)
	else:
		sprite.modulate = Color(1,1,1,1)
	
	if movement:
		var direction := Input.get_vector("left", "right", "up", "down")
		
		match current_state:
			State.NORMAL:
				handle_normal(direction)
			State.DODGING:
				handle_dodge()
				
	crosshair.global_position = crosshair.get_global_mouse_position()
	move_and_slide()

func dodge(direction):
	hitbox.disabled = true
	current_state = State.DODGING
	roll_direction = direction.normalized()
	dodge_timer.start()

func handle_dodge():
	velocity = roll_direction * DODGE_SPEED

func on_dodge_finished():
	current_state = State.NORMAL
	hitbox.disabled = false

func handle_normal(direction):
	if direction:
		velocity = direction * SPEED
		if Input.is_action_just_pressed("dodge"):
			dodge(direction)
	else:
		velocity = velocity.move_toward(Vector2.ZERO, SPEED)
