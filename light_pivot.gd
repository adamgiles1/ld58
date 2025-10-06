extends Node3D

@export var axis: Vector3
@export var speed: float

func _process(delta) -> void:
	rotate(axis, delta * speed)
