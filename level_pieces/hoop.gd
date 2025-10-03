extends Node3D

@onready var area: Area3D = $Area3D

var is_hit: bool = false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	area.body_entered.connect(on_ball_collide)

func on_ball_collide():
	if is_hit:
		return
	print("ball hit ring")
	is_hit = true
	Signals.HOOP_HIT.emit()
