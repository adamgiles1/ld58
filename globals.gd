class_name Globals extends Object

static var levels: Array[PackedScene] = [
	preload("res://levels/level1.tscn"),
	preload("res://levels/level2.tscn")
]

static var current_level: int = 0

static func get_next_level() -> PackedScene:
	current_level += 1
	if current_level < levels.size():
		return levels[current_level]
	
	print("cannot find next level, returning first level")
	current_level = 0
	return levels[current_level]
