extends Control


func _ready() -> void:
	$CenterContainer/PanelContainer/MarginContainer/VBoxContainer/BackButton.pressed.connect(_on_back_button_pressed)


func _on_back_button_pressed() -> void:
	get_tree().change_scene_to_file("res://main_menu.tscn")
