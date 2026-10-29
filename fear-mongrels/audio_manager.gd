
extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer


func _ready():
	music_player.stop()
	music_player.stream = null


func play_main_theme():
	pass


func play_dagon_intro():
	pass
