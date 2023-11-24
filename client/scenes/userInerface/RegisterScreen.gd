extends Control

@onready var http : HTTPRequest = $HTTPRequest
@onready var username : LineEdit = $VBoxContainer/username/LineEdit
@onready var password : LineEdit = $VBoxContainer/password/LineEdit
@onready var confirm : LineEdit = $VBoxContainer/confirm/LineEdit
@onready var notification : Label = $VBoxContainer/notification/Label


func _on_HTTPRequest_request_completed(result: int, response_code: int, headers: PackedStringArray, body:PackedByteArray) -> void:
	var test_json_conv = JSON.new()
	test_json_conv.parse(body.get_string_from_ascii())
	var response_body := test_json_conv.get_data()
	if response_code != 200:
		notification.text = response_body.result.error.message.capitalize()
	else:
		notification.text = "Registration successful"
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/userInerface/LoginScreen.tscn")


func _on_Button_pressed() -> void:
	if password.text != confirm.text or username.text.is_empty() or password.text.is_empty():
		notification.text = "Invalid password or username"
		return
	#Firebase.register(username.text, password.text, http)
