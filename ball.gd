class_name Ball extends RigidBody3D

@onready var power_slider = %PowerSlider
@onready var aim_slider = %AimSlider

@onready var shoot_button = %ShootButton
@onready var debug_info = %DebugInfo

@onready var path_preview = %PathPreview
@onready var ball_cam = %BallCam

@onready var model_meshes = [
		$Turtle/Body,
		$Turtle/Body/NeckOrigin/Neck,
		$Turtle/Body/NeckOrigin/Neck/HeadOrigin/Head,
		$Turtle/Body/LeftFlipperOrigin/LeftFlipper,
		$Turtle/Body/RightFlipperOrigin/RightFlipper,
		$Turtle/Body/LeftFootOrigin/LeftFoot,
		$Turtle/Body/RightFootOrigin/RightFoot
	]

@onready var neck_origin = $Turtle/Body/NeckOrigin
@onready var head_origin = $Turtle/Body/NeckOrigin/Neck/HeadOrigin
@onready var left_flipper_origin = $Turtle/Body/LeftFlipperOrigin
@onready var right_flipper_origin = $Turtle/Body/RightFlipperOrigin
@onready var left_foot_origin = $Turtle/Body/LeftFootOrigin
@onready var right_foot_origin = $Turtle/Body/RightFootOrigin

var left_flipper_tween
var right_flipper_tween

@onready var shot_sound: AudioStreamPlayer = $ShotSound
@onready var powering_up_sound: AudioStreamPlayer = $PoweringSound

var cam_offset = Vector3(0, 1, 2)
var cam_angle = 0
var cam_height = 0.5
var mouse_sensitivity = 0.003
var cam_zoom = 1
var scroll_sensitivity = 0.1

var height_select = 0
const height_values = [.25, .5, 1.0]

var shot_charge = 0

var active_shot = false

var reset_point: Vector3
var reset_velocity_on_next_frame := false
var last_frame_position: Vector3
var time_since_last_bump := 0.0

var is_ghost := false
var ghost_init := false
var ghost_vel: Vector3

func _ready() -> void:
	if !is_ghost:
		shoot_button.pressed.connect(_shoot_button_is_pressed)
		reset_point = global_position
		Engine.time_scale = 0.5
		last_frame_position = global_position
		set_idle_anim()
		body_entered.connect(on_body_entered)

func get_height() -> float:
	return height_values[height_select]

func calculate_shot() -> Vector3:
	if GameUI.paused:
		var angle_rad = aim_slider.value * PI/50
		var power = power_slider.value * 0.02
		return Vector3(sin(angle_rad), get_height(), cos(angle_rad)) * power
	else:
		var power = get_charge_power(shot_charge)
		var flat_rot = -ball_cam.global_basis.z
		flat_rot.y = 0
		flat_rot = flat_rot.normalized()
		return (flat_rot + Vector3.UP * get_height()).normalized() * power * 1.5

func _process(delta: float) -> void:
	if is_ghost:
		if ghost_init:
			ghost_init = false
			ghost_shoot(ghost_vel)
		return
	time_since_last_bump += delta
	if Input.is_action_just_pressed("HeightUp"):
		height_select += 1
		if height_select >= len(height_values):
			height_select = 0
	if Input.is_action_just_pressed("HeightDown"):
		height_select -= 1
		if height_select < 0:
			height_select += len(height_values)
		
	if !active_shot:
		if Input.is_action_pressed("Shoot"):
			shot_charge += delta
			set_charge_anim(get_charge_power(shot_charge))
		if Input.is_action_just_released("Shoot"):
			shoot()
			shot_charge = 0
			active_shot = true
	
	if shot_charge != 0:
		powering_up_sound.pitch_scale = abs(sin(shot_charge * 5)) / 2
		powering_up_sound.volume_db = -5
		powering_up_sound.play()
	else:
		powering_up_sound.stop()
	
	var shot = calculate_shot()
	var shot_length = shot.length()
	if shot_length > 0:
		# path_preview.global_basis = Basis.looking_at(shot)
		look_at(global_position + Vector3(shot.x, 0, shot.z))
		path_preview.look_at(global_position + shot)
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
	ball_cam.look_at(global_position + Vector3.UP * cam_zoom * 0.3)
	
	if active_shot and (global_position.y < -5): #Better conditions here for when a shot is basically over
		GameUI.instance.reset_reminder.visible = true
		
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
	if is_ghost:
		return
	if reset_velocity_on_next_frame:
		reset_velocity_on_next_frame = false
		state.linear_velocity = Vector3.ZERO
		state.angular_velocity = Vector3.ZERO
		global_position = reset_point
		last_frame_position = reset_point # do this to prevent the raycast from checking for any hoops between reset_point and end of shot
	
	
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
	var velocity = calculate_shot()
	print("shot velocity: ", velocity)
	var shot_length = velocity.length()
	
	var tween = create_tween()
	tween.tween_interval(0.05)
	tween.tween_callback(apply_impulse.bind(velocity))
	tween.tween_callback(apply_torque.bind(-global_basis.x * shot_length * 0.03))
	set_shot_anim(0.1)
	# Output shot details here
	path_preview.visible = false
	active_shot = true
	Signals.STROKE.emit(velocity, global_position)
	$ShotSound.play()

func ghost_shoot(shot_vel: Vector3) -> void:
	print("ghost velocity: ", shot_vel)
	var shot_length = shot_vel.length()
	set_charge_anim(shot_length / 1.5)
	var tween = create_tween()
	tween.tween_interval(0.05)
	tween.tween_callback(apply_impulse.bind(shot_vel))
	tween.tween_callback(apply_torque.bind(-global_basis.x * shot_length * 0.03))
	set_shot_anim(0.1)
	$ShotSound.play()
	
	#apply_impulse.(shot_vel)
	#apply_torque(-global_basis.x * shot_vel.length() * 0.3)

func reset() -> void:
	reset_velocity_on_next_frame = true
	path_preview.visible = true
	active_shot = false
	set_idle_anim()
	GameUI.instance.reset_reminder.visible = false
	if left_flipper_tween:
		left_flipper_tween.kill()
	if right_flipper_tween:
		right_flipper_tween.kill()

func set_as_ghost(shot_vel: Vector3) -> void:
	collision_layer = 8
	is_ghost = true
	ghost_init = true
	ghost_vel = shot_vel
	path_preview.visible = false
	body_entered.disconnect(on_body_entered)
	
	for mesh in model_meshes:
		var material: StandardMaterial3D = mesh.get_active_material(0)
		material = material.duplicate()
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var color: Color = material.albedo_color
		color.a = .2
		material.albedo_color = color
		mesh.set_surface_override_material(0, material)
		
func get_charge_power(charge: float) -> float:
	return abs(sin(charge * 5))
		
func set_idle_anim() -> void:
	left_flipper_origin.rotation_degrees = Vector3(0, -90, 0)
	right_flipper_origin.rotation_degrees = Vector3(0, -90, 0)

func set_charge_anim(power: float) -> void:
	left_flipper_origin.rotation_degrees = Vector3(10 + 160 * pow(1 - power, 3), -90, 70)
	right_flipper_origin.rotation_degrees = Vector3(10 + 160 * pow(1 - power, 3), -90, -70)

func set_shot_anim(flick_duration: float) -> void:
	if left_flipper_tween:
		left_flipper_tween.kill()
	left_flipper_tween = create_tween()
	left_flipper_tween.tween_property(left_flipper_origin, "rotation_degrees", Vector3(170, -90, 70), flick_duration).set_trans(Tween.TRANS_EXPO)
	left_flipper_tween.tween_interval(0.1)
	left_flipper_tween.tween_property(left_flipper_origin, "rotation_degrees", Vector3(0, -90, 0), 0.1)
	
	if right_flipper_tween:
		right_flipper_tween.kill()
	right_flipper_tween = create_tween()
	right_flipper_tween.tween_property(right_flipper_origin, "rotation_degrees", Vector3(170, -90, -70), flick_duration).set_trans(Tween.TRANS_EXPO)
	right_flipper_tween.tween_interval(0.1)
	right_flipper_tween.tween_property(right_flipper_origin, "rotation_degrees", Vector3(0, -90, 0), 0.1)

func on_body_entered(body: Node) -> void:
	if is_ghost || body is Ball:
		return
	print("hit something: ", body)
	if time_since_last_bump < .1:
		return
	$HitSound.pitch_scale = randf_range(.8, 1.2)
	$HitSound.play()
	time_since_last_bump = 0.0
