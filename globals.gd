class_name Globals extends Object

static var levels: Array[PackedScene] = [
	load("res://levels/level1.tscn"),
	load("res://levels/level2.tscn"),
	load("res://levels/level3.tscn"),
	load("res://levels/level4.tscn"),
	load("res://levels/level5.tscn")
]

static var current_level: int = 0

static func get_next_level() -> PackedScene:
	print("getting next level from ", current_level)
	current_level += 1
	if current_level < levels.size():
		return levels[current_level]
	
	print("cannot find next level, returning first level")
	current_level = 0
	return levels[current_level]
