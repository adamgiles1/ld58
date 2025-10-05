extends Node

signal HOOP_HIT
signal STROKE(velocity: Vector3, from: Vector3)
signal GHOSTS_RETRIEVED(ghosts: Array[StrokeInfo])
signal LEVEL_COMPLETE(level: int, score: int)

var ui_scene = preload("res://ui/GameUI.tscn")

func _ready() -> void:
	var ui = ui_scene.instantiate()
	add_child(ui)
