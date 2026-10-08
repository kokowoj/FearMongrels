extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer

var main_theme = preload("res://audio/Main theme.wav")
var dagon_intro = preload("res://audio/Cathulhu - intro scene.wav")


func _ready():
	get_tree().node_added.connect(_on_node_added)
	call_deferred("_update_music")


func _on_node_added(node):
	if node == get_tree().current_scene:
		call_deferred("_update_music")


func _update_music():
	var scene = get_tree().current_scene

	if scene == null:
		return

	var scene_name = scene.scene_file_path.get_file().get_basename().to_lower()

	if scene_name.contains("dagon_test"):
		play_dagon_intro()
	else:
		play_main_theme()


func play_main_theme():
	if music_player.stream == main_theme and music_player.playing:
		return

	music_player.stop()
	music_player.stream = main_theme
	music_player.play()


func play_dagon_intro():
	if music_player.stream == dagon_intro and music_player.playing:
		return

	music_player.stop()
	music_player.stream = dagon_intro
	music_player.play()
