extends CharacterBody3D

@onready var mesh: MeshInstance3D = $KennyMesh/Skeleton3D/Kenny
@onready var kenny: Node3D = $KennyMesh
@onready var gun: MeshInstance3D = $KennyMesh/Skeleton3D/BoneAttachment3D/Gun
@onready var crosshair: ColorRect = $UI/Crosshair
@onready var hitbox: CollisionShape3D = $CollisionShape3D
@onready var anim_player: AnimationPlayer = $KennyMesh/AnimationPlayer
@export var ANIM_BLEND_TIME: float = 0.2
@export var STEP_INTERVAL: float = 0.35  # Time in seconds between each footstep ripple
var step_timer: float = 0.0
@onready var ripples: GPUParticles3D = $FootstepRipples
enum State {NORMAL, DODGING}
var movement = true
@export var can_shoot = true
var can_roll = true
@export var SPEED = 5.0
@export var DODGE_SPEED = 15.0
@export var DODGE_DURATION = 0.35

@export var max_dodges = 3
@export var recharge_time = 3.0
@onready var dodge_timer: Timer = $Dodge
@onready var fatigue: Timer = $Fatigue

var active_cooldowns: Array[float] = []
@onready var debug_dodges: Label = $UI/DebugDodges
@onready var debug_health: Label = $UI/Health

var current_state: State = State.NORMAL
var roll_direction := Vector3.ZERO

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_CONFINED_HIDDEN
	dodge_timer.timeout.connect(on_dodge_finished)
	

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			shoot()

func shoot():
	var crosshair_tween
	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()
		
	crosshair.scale = Vector2.ONE
	crosshair.rotation = 0.0
	crosshair_tween = get_tree().create_tween()
	crosshair_tween.set_parallel(true)
	
	var random_spin := randf_range(-0.6, 0.6)
	
	crosshair_tween.tween_property(crosshair, "scale", Vector2(2.0, 2.0), 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	crosshair_tween.tween_property(crosshair, "rotation", random_spin, 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	crosshair_tween.chain().tween_property(crosshair, "scale", Vector2.ONE, 0.15)\
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	crosshair_tween.parallel().tween_property(crosshair, "rotation", 0.0, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func blank():
	var crosshair_tween
	
	if crosshair_tween and crosshair_tween.is_valid():
		crosshair_tween.kill()
		
	crosshair.scale = Vector2.ONE
	crosshair.rotation = 0.0
	crosshair_tween = get_tree().create_tween()
	
	var random_spin := randf_range(-0.6, 0.6)
	crosshair_tween.tween_property(crosshair, "rotation", random_spin, 0.08)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	crosshair_tween.tween_property(crosshair, "rotation", 0.0, 0.15)\
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	
func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= ProjectSettings.get_setting("physics/3d/default_gravity") * delta
	
	var current_dodges = max_dodges - active_cooldowns.size()
	debug_dodges.text = "Dodges: " + str(current_dodges)
	debug_health.text = "Health: " + str(GameState.player_health)
	
	for i in range(active_cooldowns.size() - 1, -1, -1):
		active_cooldowns[i] -= delta
		if active_cooldowns[i] <= 0.0:
			active_cooldowns.remove_at(i)
			
	if hitbox.disabled:
		mesh.get_active_material(0).albedo_color = Color(0.5, 1, 0.5, 0.5)
	else:
		mesh.get_active_material(0).albedo_color = Color(1, 1, 1, 1)
	
	if movement:
		var input_dir := Input.get_vector("left", "right", "down", "up")
		
		var direction := Vector3.ZERO
		if input_dir != Vector2.ZERO:
			var cam = get_viewport().get_camera_3d()
			var cam_forward = -cam.global_transform.basis.z
			var cam_right = cam.global_transform.basis.x
			
			cam_forward.y = 0.0
			cam_right.y = 0.0
			cam_forward = cam_forward.normalized()
			cam_right = cam_right.normalized()
			
			direction = (cam_right * input_dir.x + cam_forward * input_dir.y).normalized()
		
		match current_state:
			State.NORMAL:
				handle_normal(direction)
			State.DODGING:
				handle_dodge()
				
	crosshair.position = get_viewport().get_mouse_position()
	move_and_slide()
	
	rotate_mesh_to_cursor()

func run_footstep_logic(delta: float) -> void:
	step_timer -= delta
	
	if step_timer <= 0.0:
		# Trigger the particle burst if we are firmly on the map floor
		if is_on_floor() and ripples:
			ripples.restart()
			ripples.emitting = true
			
		# Reset the timer cycle
		step_timer = STEP_INTERVAL

func handle_normal(direction: Vector3):
	if direction != Vector3.ZERO:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
		
		# 1. Run the procedural step timer while moving
		run_footstep_logic(get_physics_process_delta_time())
		
		# Update animations based on movement relative to where we look
		update_strafe_animation(direction)
	else:
		velocity.x = move_toward(velocity.x, 0, SPEED)
		velocity.z = move_toward(velocity.z, 0, SPEED)
		
		# 2. Reset the timer when standing still so the next step triggers instantly
		step_timer = 0.0
		
		if anim_player.current_animation != "pistol idle/mixamo_com":
			anim_player.play("pistol idle/mixamo_com", ANIM_BLEND_TIME)
		
	if Input.is_action_just_pressed("dodge"):
		if direction != Vector3.ZERO:
			dodge(direction)

func update_strafe_animation(move_dir: Vector3) -> void:
	var forward_dir: Vector3 = kenny.global_transform.basis.z.normalized()
	var right_dir: Vector3 = kenny.global_transform.basis.x.normalized()
	var forward_dot: float = move_dir.dot(forward_dir)
	var right_dot: float = move_dir.dot(right_dir)
	
	var target_anim: String = "pistol idle/mixamo_com"
	
	if abs(forward_dot) >= abs(right_dot):
		if forward_dot > 0.2:
			target_anim = "pistol walk/mixamo_com"
		elif forward_dot < -0.2:
			target_anim = "pistol walk backward/mixamo_com"
	else:
		if right_dot > 0.2:
			target_anim = "pistol strafe/mixamo_com"  
		elif right_dot < -0.2:
			target_anim = "pistol strafe (2)/mixamo_com"
			
	if anim_player.current_animation != target_anim:
		
		anim_player.play(target_anim, ANIM_BLEND_TIME)

func trigger_footstep_ripple() -> void:
	# Only emit ripples if we are firmly touching the level floor
	if is_on_floor():
		$FootstepRipples.restart()
		$FootstepRipples.emitting = true

func dodge(direction):
	var current_dodges = max_dodges - active_cooldowns.size()
	if current_dodges <= 0:
		return
	else:
		active_cooldowns.append(recharge_time)
		
	hitbox.disabled = true
	current_state = State.DODGING
	roll_direction = direction.normalized()
	dodge_timer.start()

func handle_dodge():
	velocity = roll_direction * DODGE_SPEED

func on_dodge_finished():
	current_state = State.NORMAL
	hitbox.disabled = false

func rotate_mesh_to_cursor() -> void:
	var camera = get_viewport().get_camera_3d()
	if not camera: return
	
	var mouse_pos = get_viewport().get_mouse_position()
	var ray_origin = camera.project_ray_origin(mouse_pos)
	var ray_normal = camera.project_ray_normal(mouse_pos)
	var ray_end = ray_origin + ray_normal * 1000.0
	
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(ray_origin, ray_end)
	query.exclude = [get_rid()] 
	
	var result = space_state.intersect_ray(query)
	
	if result:
		var target_point: Vector3 = result.position
		
		var direction_to_cursor = target_point - kenny.global_position
		
		var inverted_direction = Vector3(-direction_to_cursor.x, 0.0, -direction_to_cursor.z)

		var kenny_target = kenny.global_position + inverted_direction
		
		if direction_to_cursor.length() > 0.1:
			kenny.look_at(kenny_target, Vector3.UP)
