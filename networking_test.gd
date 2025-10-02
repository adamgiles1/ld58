extends Control


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	$SendButton.pressed.connect(send_data)
	$ReceiveButton.pressed.connect(get_data)


func send_data():
	AwsService.send_data()
	
func get_data():
	AwsService.get_data()
