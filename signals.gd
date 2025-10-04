extends Node

signal HOOP_HIT
signal STROKE

var ui_scene = preload("res://ui/GameUI.tscn")

func _ready() -> void:
	var ui = ui_scene.instantiate()
	add_child(ui)