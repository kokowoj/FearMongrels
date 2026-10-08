extends Control

func _ready():
	$VBoxContainer/ConfirmButton.pressed.connect(_on_confirm_button_pressed)

func _on_confirm_button_pressed():
	get_tree().change_scene_to_file("res://dagon_testing.tscn")
