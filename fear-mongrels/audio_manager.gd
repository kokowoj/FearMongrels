extends Node

@onready var music_player: AudioStreamPlayer = $MusicPlayer

const MAIN_THEME = preload("res://audio/Main theme.wav")
const SELECT_FIGHTER = preload("res://audio/select your fighter.wav")
const START_MATCH = preload("res://audio/Start Match.wav")
const INTRO_THEME = preload("res://audio/Cathulhu - intro scene.wav")
const FIGHT_THEME = preload("res://audio/Cathulhu - fight theme.wav")
const VICTORY_THEME = preload("res://audio/Cathulhu - victory theme.wav")

var transition_player: AudioStreamPlayer
var music_sequence: int = 0


func _ready() -> void:
	music_player.stop()
	music_player.stream = null

	if AudioServer.get_bus_index("Music") != -1:
		music_player.bus = "Music"

	transition_player = AudioStreamPlayer.new()
	transition_player.name = "TransitionPlayer"
	add_child(transition_player)

	if AudioServer.get_bus_index("SFX") != -1:
		transition_player.bus = "SFX"

	_set_loop(MAIN_THEME, false)
	_set_loop(SELECT_FIGHTER, false)
	_set_loop(START_MATCH, false)
	_set_loop(INTRO_THEME, false)
	_set_loop(FIGHT_THEME, true)
	_set_loop(VICTORY_THEME, false)


func _set_loop(stream: AudioStream, enabled: bool) -> void:
	if stream is AudioStreamWAV:
		if enabled:
			stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
		else:
			stream.loop_mode = AudioStreamWAV.LOOP_DISABLED


func _play_music(stream: AudioStream) -> void:
	music_sequence += 1
	music_player.stop()
	music_player.stream = stream
	music_player.play()


func stop_music() -> void:
	music_sequence += 1
	music_player.stop()


func play_main_theme() -> void:
	transition_player.stop()
	_play_music(MAIN_THEME)


func play_select_fighter() -> void:
	transition_player.stop()
	_play_music(SELECT_FIGHTER)


func play_start_match() -> void:
	stop_music()

	transition_player.stop()
	transition_player.stream = START_MATCH
	transition_player.play()

	await transition_player.finished


func play_dagon_intro() -> void:
	stop_music()

	_play_music(INTRO_THEME)
	var sequence := music_sequence

	await music_player.finished

	if sequence != music_sequence:
		return

	_play_music(FIGHT_THEME)


func play_fight_theme() -> void:
	_play_music(FIGHT_THEME)


func play_victory_theme() -> void:
	transition_player.stop()
	_play_music(VICTORY_THEME)
