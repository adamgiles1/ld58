class_name GameManager extends Node3D

var ball_scn: PackedScene = load("res://Ball.tscn")

var hoops_to_hit: int = 0
var hoops_hit: int = 0

var strokes: int = 0
var stroke_stats: Array[StrokeInfo] = []

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	print("GAME MANAGER HI")
	var hoops = get_tree().get_nodes_in_group("hoop")
	hoops_to_hit = len(hoops)
	for hoop in hoops:
		hoop.game_manager = self
	print("Initialized with ", hoops_to_hit, " hoops")
	Signals.STROKE.connect(on_stroke)

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("ui_cut"):
		spawn_ghost_ball(Vector3(3, 1, 1), Vector3(0, 0, 0)) # todo remove

func on_hoop_hit():
	hoops_hit += 1
	print("hoops hit: ", hoops_hit, "/", hoops_to_hit)
	if hoops_hit >= hoops_to_hit:
		print("Last hoop hit")
		
		# send up to two shots at random to server
		var shots_to_send: Array[StrokeInfo] = []
		if len(stroke_stats) < 3:
			shots_to_send = stroke_stats
		else:
			stroke_stats.shuffle()
			shots_to_send.append(stroke_stats.pop_back())
			shots_to_send.append(stroke_stats.pop_back())
		AwsService.send_strokes(shots_to_send)
		
		await get_tree().create_timer(1.0).timeout
		load_next_level()

func on_hoop_exist():
	print("hoop registered")
	hoops_to_hit += 1

func on_stroke(velocity: Vector3, from: Vector3):
	strokes += 1
	print("strokes taken: ", strokes)
	
	stroke_stats.append(StrokeInfo.new(velocity, from, Globals.get_current_level_id()))

func load_next_level() -> void:
	var next_level := Globals.get_next_level()
	get_tree().change_scene_to_packed(next_level)

func spawn_ghost_ball(velocity: Vector3, from: Vector3) -> void:
	print("spawning ghostball with velocity: ", velocity)
	var ghost: Ball = ball_scn.instantiate()
	add_child(ghost)
	ghost.set_as_ghost(velocity)
	ghost.global_position = from
