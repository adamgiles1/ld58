extends RigidBody3D

@onready var height_slider = %HeightSlider
@onready var power_slider = %PowerSlider
@onready var aim_slider = %AimSlider

@onready var shoot_button = %ShootButton
@onready var debug_info = %DebugInfo

const height_values = [1, 2, 3]

func _ready() -> void:
	shoot_button.pressed.connect(_shoot_button_is_pressed)

func get_height() -> float:
	return height_values[height_slider.value]

func calculate_shot() -> Vector3:
	var angle_rad = aim_slider.value * PI/50
	var power = power_slider.value * 0.1
	return Vector3(sin(angle_rad), get_height(), cos(angle_rad)) * power

func _process(_delta: float) -> void:
	var info_text = "height: %s\n" % height_slider.value
	info_text += "power: %s\n" % power_slider.value
	info_text += "aim: %s\n" % aim_slider.value
	info_text += "shot vector: %s" % calculate_shot()
	debug_info.text = info_text

func _shoot_button_is_pressed() -> void:
	apply_impulse(calculate_shot())
