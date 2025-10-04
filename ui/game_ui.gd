class_name GameUI extends Control

static var instance
static var paused = false

@onready var gameplay_ui = %GameplayUI
@onready var stroke_label = %StrokeLabel
@onready var reset_reminder = %ResetReminder
# Add height indicator + change height controls (WS)
# Hook up real stroke count

@onready var menu_ui = %MenuUI
@onready var level1_button = %Level1Button
@onready var level2_button = %Level2Button
@onready var level3_button = %Level3Button
@onready var level4_button = %Level4Button
@onready var level5_button = %Level5Button
# Add "Best score" trackers, add real values, etc. Indicate if collectible is obtained, add new "collectibles" tab??

# Pausing doesn't actually pause, but we could change that, just brings up the menu and gives you your cursor

func _ready() -> void:
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gameplay_ui.visible = true
	menu_ui.visible = false
	reset_reminder.visible = false
	instance = self
	# Yuck
	level1_button.pressed.connect(load_level.bind(0))
	level2_button.pressed.connect(load_level.bind(1))
	level3_button.pressed.connect(load_level.bind(2))
	level4_button.pressed.connect(load_level.bind(3))
	level5_button.pressed.connect(load_level.bind(4))
	
func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("Pause"):
		paused = !paused
		gameplay_ui.visible = !paused
		menu_ui.visible = paused
		if paused:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
func load_level(level_index: int) -> void:
	Globals.current_level = level_index
	get_tree().change_scene_to_packed(Globals.levels[level_index])
	paused = false
	gameplay_ui.visible = true
	menu_ui.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	
