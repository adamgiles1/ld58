class_name GameUI extends Control

static var instance
static var paused = false

var strokes = 0

# NEWLEVEL
var stroke_pars = [3, 1, 4, 2, 3, 5]
# NEWLEVEL
var stroke_records = [-1, -1, -1, -1, -1, -1]
# NEWLEVEL
var collectibles = [false, false, false, false, false, false]

@onready var gameplay_ui = %GameplayUI
@onready var stroke_label = %StrokeLabel
@onready var stroke_height_label = %StrokeHeightLabel
@onready var reset_reminder = %ResetReminder
@onready var popup = %Popup

var popup_timer = 0
# Add height indicator + change height controls (WS)
# Hook up real stroke count

@onready var menu_ui = %MenuUI
# NEWLEVEL
@onready var level1_button = %Level1Button
@onready var level1_score = %Level1Score
@onready var level2_button = %Level2Button
@onready var level2_score = %Level2Score
@onready var level3_button = %Level3Button
@onready var level3_score = %Level3Score
@onready var level4_button = %Level4Button
@onready var level4_score = %Level4Score
@onready var level5_button = %Level5Button
@onready var level5_score = %Level5Score
@onready var level6_button = %Level6Button
@onready var level6_score = %Level6Score

@onready var volume_slider = %VolumeSlider
# Add "Best score" trackers, add real values, etc. Indicate if collectible is obtained, add new "collectibles" tab??
# Pausing doesn't actually pause, but we could change that, just brings up the menu and gives you your cursor

func _ready() -> void:
	paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	gameplay_ui.visible = true
	menu_ui.visible = false
	reset_reminder.visible = false
	popup.visible = false
	instance = self

	# NEWLEVEL
	level1_button.pressed.connect(load_level.bind(0))
	level2_button.pressed.connect(load_level.bind(1))
	level3_button.pressed.connect(load_level.bind(2))
	level4_button.pressed.connect(load_level.bind(3))
	level5_button.pressed.connect(load_level.bind(4))
	level6_button.pressed.connect(load_level.bind(5))
	
	Signals.STROKE.connect(_on_stroke)
	Signals.LEVEL_COMPLETE.connect(_on_level_complete)
	
func _process(delta: float) -> void:
	AudioServer.set_bus_volume_db(0, linear_to_db(volume_slider.value * 0.01))
	if popup_timer > 0:
		popup_timer -= delta
		if popup_timer <= 0:
			popup.visible = false
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
	reset_reminder.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	popup_timer = 0
	popup.visible = false
	strokes = 0
	stroke_label.text = "Strokes: 0/%s" % stroke_pars[Globals.current_level]
	set_stroke_height("Low")
	
static func level_loaded() -> void:
	paused = false
	instance.gameplay_ui.visible = true
	instance.menu_ui.visible = false
	instance.reset_reminder.visible = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	instance.popup_timer = 0
	instance.popup.visible = false
	instance.strokes = 0
	instance.stroke_label.text = "Strokes: 0/%s" % instance.stroke_pars[Globals.current_level]
	set_stroke_height("Low")
	
static func set_stroke_height(height_text: String) -> void:
	instance.stroke_height_label.text = "Stroke Height: %s" % height_text
	
func _on_stroke(_velocity, _position) -> void:
	strokes += 1
	stroke_label.text = "Strokes: %s" % strokes
	
func _on_level_complete(level: int, strokes: int) -> void:
	if stroke_records[level] < 0 or stroke_records[level] > strokes:
		stroke_records[level] = strokes
	if !collectibles[level] and strokes <= stroke_pars[level]:
		collectibles[level] = true
		popup.visible = true
		popup_timer = 0.8
		
	# NEWLEVEL
	update_score_text(0, level1_score)
	update_score_text(1, level2_score)
	update_score_text(2, level3_score)
	update_score_text(3, level4_score)
	update_score_text(4, level5_score)
	update_score_text(5, level6_score)
	
func update_score_text(index: int, level_score: Label) -> void:
	var record = stroke_records[index]
	if record < 0:
		level_score.text = "No Score"
	else:
		level_score.text = "Best Score: %s" % record
	if collectibles[index]:
		level_score.text += "!"
		level_score.add_theme_color_override("font_color", Color.GOLD)
