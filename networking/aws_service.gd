extends Node

var send_data_node: HTTPRequest
var get_data_node: HTTPRequest

var is_sending := false
var is_getting := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	send_data_node = HTTPRequest.new()
	send_data_node.request_completed.connect(send_data_response)
	
	get_data_node = HTTPRequest.new()
	get_data_node.request_completed.connect(get_data_response)
	
	
	add_child(send_data_node)
	add_child(get_data_node)

func send_data():
	print("sending data")
	var headers = ["Content-Type: application/json"]
	var body = {
		"value1": 16,
		"value2": "hello again again FROM ANSON",
		"value3": "theId or is itttt HI"
	}
	var json = JSON.stringify(body)
	send_data_node.request("https://jkx6qkm4vh.execute-api.us-east-1.amazonaws.com/default/ld58-send-stuff", headers, HTTPClient.METHOD_POST, json)

func send_strokes(shots: Array[StrokeInfo]) -> void:
	print("sending shots")
	var headers = ["Content-Type: application/json"]
	
	for shot in shots:
		var body = {
			"level": shot.level,
			"fromX": shot.from.x,
			"fromY": shot.from.y,
			"fromZ": shot.from.z,
			"velX": shot.velocity.x,
			"velY": shot.velocity.y,
			"velZ": shot.velocity.z
		}
		var json = JSON.stringify(body)
		
		if is_sending:
			print("waiting for previous request to finish")
			await send_data_node.request_completed
		print("sending shot")
		send_data_node.request("https://jkx6qkm4vh.execute-api.us-east-1.amazonaws.com/default/ld58-send-stuff", headers, HTTPClient.METHOD_POST, json)
		is_sending = true
func get_data():
	print("getting data")
	var headers = ["Content-Type: application/json"]
	get_data_node.request("https://lie56uzg51.execute-api.us-east-1.amazonaws.com/default/ld58-get-stuff", headers, HTTPClient.METHOD_GET, "")

func send_data_response(result: int, code: int, headers: PackedStringArray, body: PackedByteArray):
	is_sending = false
	print("send-data result: ", code)
	print("body: ", body.get_string_from_utf8())

func get_data_response(result: int, code: int, headers: PackedStringArray, body: PackedByteArray):
	print("get-data result: ", result)
	var parsed: Array = JSON.parse_string(body.get_string_from_utf8())
	var res: Dictionary = parsed[2]
	print("index 1: ", res)
