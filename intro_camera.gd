class_name IntroCamera extends Camera3D

static var instance

func _ready() -> void:
	instance = self
	
static func new_pose() -> void:
	var vector = Vector3.ZERO
	while true:
		vector = Vector3(randf() * 2 - 1, randf() * 2 - 1, randf() * 2 - 1)
		if vector.length_squared() < 1:
			break;
	instance.global_position = vector + Vector3.UP * 0.5
	instance.look_at(Vector3.UP * 0.5)
