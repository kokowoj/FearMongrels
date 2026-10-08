extends Control


func _ready() -> void:
	var label = $QuitGame.get_label()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _on_start_pressed() -> void:
	get_tree().change_scene_to_file("res://player_select.tscn")


func _on_settings_pressed() -> void:
	get_tree().change_scene_to_file("res://settings.tscn")


func _on_credits_pressed() -> void:
	get_tree().change_scene_to_file("res://credits.tscn")


func _on_quit_pressed() -> void:
	$QuitGame.popup_centered()


func _on_quit_game_confirmed() -> void:
	get_tree().quit()
