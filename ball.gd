extends RigidBody3D

@onready var power_slider = %PowerSlider
@onready var aim_slider = %AimSlider

@onready var shoot_button = %ShootButton
@onready var debug_info = %DebugInfo

@onready var path_preview = %PathPreview
@onready var ball_cam = %BallCam
var cam_offset = Vector3(0, 1, 2)
var cam_angle = 0
var cam_height = 0.5
var mouse_sensitivity = 0.003
var cam_zoom = 1
var scroll_sensitivity = 0.1

var height_select = 0
const height_values = [.25, .5, 1.0]

var shot_charge = 0

var reset_point: Vector3
var reset_velocity_on_next_frame := false
var last_frame_position: Vector3

func _ready() -> void:
	shoot_button.pressed.connect(_shoot_button_is_pressed)
	reset_point = global_position
	Engine.time_scale = 0.5
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	last_frame_position = global_position

func get_height() -> float:
	return height_values[height_select]

func calculate_shot() -> Vector3:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		var angle_rad = aim_slider.value * PI/50
		var power = power_slider.value * 0.02
		return Vector3(sin(angle_rad), get_height(), cos(angle_rad)) * power
	else:
		var power = abs(sin(shot_charge * 5))
		var flat_rot = -ball_cam.global_basis.z
		flat_rot.y = 0
		flat_rot = flat_rot.normalized()
		return (flat_rot + Vector3.UP * get_height()) * power

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("HeightUp"):
		height_select += 1
		if height_select >= len(height_values):
			height_select = 0
	if Input.is_action_just_pressed("HeightDown"):
		height_select -= 1
		if height_select < 0:
			height_select += len(height_values)
			
	if Input.is_action_pressed("Shoot"):
		shot_charge += delta
	if Input.is_action_just_released("Shoot"):
		shoot()
		shot_charge = 0
	
	var shot = calculate_shot()
	var shot_length = shot.length()
	if shot_length > 0:
		path_preview.global_basis = Basis.looking_at(shot)
	path_preview.mesh.size = Vector2(0.05 + shot_length * 0.02, shot_length)
	path_preview.mesh.center_offset = Vector3.FORWARD * shot_length * 0.5
	
	var info_text = "height: %s\n" % height_select
	info_text += "power: %s\n" % power_slider.value
	info_text += "aim: %s\n" % aim_slider.value
	info_text += "shot vector: %s\n" % shot
	info_text += "shot length: %s\n" % shot.length()
	info_text += "path preview position: %s\n" % path_preview.global_position
	info_text += "path preview rotation: %s\n" % path_preview.global_rotation
	info_text += "path preview scale: %s\n" % path_preview.scale
	info_text += "cam angle raw: %s" % cam_angle
	debug_info.text = info_text
	
	if Input.is_action_just_pressed("ResetBall"):
		reset()
		
	var flat_rot = Vector3(cos(cam_angle), 0, sin(cam_angle)) * (1 - cam_height)
	flat_rot += Vector3.UP * cam_height
	ball_cam.global_position = global_position + flat_rot.normalized() * cam_zoom
	ball_cam.look_at(global_position)
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		
func _input(event: InputEvent) -> void:
	if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		return
	if event is InputEventMouseMotion:
		cam_angle += event.relative.x * mouse_sensitivity
		cam_height += event.relative.y * mouse_sensitivity
		cam_height = clamp(cam_height, 0, 0.9)
	elif event is InputEventMouseButton:
		if event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_UP:
			cam_zoom -= event.factor * scroll_sensitivity
		elif event.button_index == MouseButton.MOUSE_BUTTON_WHEEL_DOWN:
			cam_zoom += event.factor * scroll_sensitivity
		cam_zoom = clamp(cam_zoom, 0.2, 2)

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
	shoot()
	
func shoot() -> void:
	apply_impulse(calculate_shot())
	# Output shot details here
	path_preview.visible = false
	Signals.STROKE.emit()

func reset() -> void:
	reset_velocity_on_next_frame = true
	path_preview.visible = true
