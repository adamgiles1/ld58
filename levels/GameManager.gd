class_name GameManager extends Node3D

var ball_scn: PackedScene = load("res://Ball.tscn")

var hoops_to_hit: int = 0
var hoops_hit: int = 0

var strokes: int = 0

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
		spawn_ghost_ball(Vector3(3, 1, 1))

func on_hoop_hit():
	hoops_hit += 1
	print("hoops hit: ", hoops_hit, "/", hoops_to_hit)
	if hoops_hit >= hoops_to_hit:
		print("Last hoop hit")
		
		await get_tree().create_timer(1.0).timeout
		load_next_level()

func on_hoop_exist():
	print("hoop registered")
	hoops_to_hit += 1

func on_stroke():
	strokes += 1
	print("strokes taken: ", strokes)

func load_next_level() -> void:
	var next_level := Globals.get_next_level()
	get_tree().change_scene_to_packed(next_level)

func spawn_ghost_ball(velocity: Vector3) -> void:
	print("spawning ghostball with velocity: ", velocity)
	var ghost: Ball = ball_scn.instantiate()
	add_child(ghost)
	ghost.set_as_ghost(velocity)
	ghost.global_position = Vector3(-8.056, .2, 0)
