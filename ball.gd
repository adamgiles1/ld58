extends RigidBody3D

@onready var height_slider = %HeightSlider
@onready var power_slider = %PowerSlider
@onready var aim_slider = %AimSlider

@onready var shoot_button = %ShootButton
@onready var debug_info = %DebugInfo

@onready var path_preview = %PathPreview

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
	var shot = calculate_shot()
	path_preview.position = shot / 2
	var shot_length = shot.length()
	if shot_length > 0:
		path_preview.global_basis = Basis.looking_at(shot)
	path_preview.scale.z = shot_length
	path_preview.scale.x = 0.5 + shot_length * 0.2
	
	var info_text = "height: %s\n" % height_slider.value
	info_text += "power: %s\n" % power_slider.value
	info_text += "aim: %s\n" % aim_slider.value
	info_text += "shot vector: %s" % shot
	info_text += "path preview scale: %s" % path_preview.scale
	debug_info.text = info_text

func _shoot_button_is_pressed() -> void:
	apply_impulse(calculate_shot())
	path_preview.visible = false
