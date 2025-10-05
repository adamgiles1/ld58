class_name StrokeInfo extends RefCounted

var level: int = -1
var velocity: Vector3
var from: Vector3

func _init(_velocity: Vector3, _from: Vector3, _level: int) -> void:
	level = _level
	from = _from
	velocity = _velocity
	
	print("StrokeInfo created: velocity=", velocity, ", from=", from, ", level=", level)
