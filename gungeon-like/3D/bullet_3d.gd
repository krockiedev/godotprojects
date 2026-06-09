extends Node3D # or Area3D / CharacterBody3D

@export var speed: float = 100
var direction: Vector3 = Vector3.ZERO

func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta

func left_screen() -> void:
	queue_free()
