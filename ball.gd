extends RigidBody3D

@onready var height_slider = %HeightSlider
@onready var power_slider = %PowerSlider
@onready var aim_slider = %AimSlider

@onready var shoot_button = %ShootButton
@onready var debug_info = %DebugInfo

@onready var path_preview = %PathPreview

const height_values = [.25, .5, 1.0]
var reset_point: Vector3
var reset_velocity_on_next_frame := false
var last_frame_position: Vector3

func _ready() -> void:
	shoot_button.pressed.connect(_shoot_button_is_pressed)
	reset_point = global_position
	last_frame_position = global_position

func get_height() -> float:
	return height_values[height_slider.value]

func calculate_shot() -> Vector3:
	var angle_rad = aim_slider.value * PI/50
	var power = power_slider.value * 0.02
	return Vector3(sin(angle_rad), get_height(), cos(angle_rad)) * power

func _process(_delta: float) -> void:
	var shot = calculate_shot()
	var shot_length = shot.length()
	if shot_length > 0:
		path_preview.global_basis = Basis.looking_at(shot)
	path_preview.mesh.size = Vector2(0.05 + shot_length * 0.02, shot_length)
	path_preview.mesh.center_offset = Vector3.FORWARD * shot_length * 0.5
	
	var info_text = "height: %s\n" % height_slider.value
	info_text += "power: %s\n" % power_slider.value
	info_text += "aim: %s\n" % aim_slider.value
	info_text += "shot vector: %s" % shot
	info_text += "path preview scale: %s" % path_preview.scale
	debug_info.text = info_text
	
	if Input.is_action_just_pressed("ResetBall"):
		reset()

func _integrate_forces(state: PhysicsDirectBodyState3D) -> void:
	if reset_velocity_on_next_frame:
		reset_velocity_on_next_frame = false
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		global_position = reset_point
	
	
	# ray cast from last position to current position to check if we hit a hoop
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(last_frame_position, global_position)
	query.collide_with_areas = true
	query.collision_mask = 4
	var ray_result = space_state.intersect_ray(query)
	if ray_result:
		var collider = ray_result.collider
		print("hit hoop")
		collider.get_owner().on_ball_collide(self)
	
	last_frame_position = global_position

func _shoot_button_is_pressed() -> void:
	apply_impulse(calculate_shot())
	# Output shot details here
	path_preview.visible = false

func reset() -> void:
	reset_velocity_on_next_frame = true
	path_preview.visible = true
