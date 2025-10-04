extends Node3D

@onready var area: Area3D = $Area3D
@onready var mesh: MeshInstance3D = $MeshInstance3D
var material: StandardMaterial3D

var is_hit: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	material = mesh.get_active_material(0)
	area.body_entered.connect(on_ball_collide)

func on_ball_collide(body: Node3D):
	if is_hit:
		return
	print("ball hit ring")
	is_hit = true
	Signals.HOOP_HIT.emit()
	mesh.material_override = preload("res://level_pieces/hoop_material_hit.tres")
