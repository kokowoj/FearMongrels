
extends Node

# Menu audio files
const MAIN_THEME = preload("res://audio/Main theme.wav")
const HOVER_SOUND = preload("res://audio/Menu Item Hover.wav")
const SELECT_SOUND = preload("res://audio/Menu Item Select.wav")

# Scenes that use menu audio
const MENU_SCENES = [
	"main_menu.tscn",
	"settings.tscn",
    "credits.tscn"
]

# Audio volumes
const MUSIC_VOLUME = -19.0
const HOVER_VOLUME = -6.0
const SELECT_VOLUME = -6.0

var music_player: AudioStreamPlayer
var hover_player: AudioStreamPlayer
var select_player: AudioStreamPlayer

var menu_active: bool = false
var current_scene_id: int = 0


func _ready() -> void:
	# Create background music player
	music_player = AudioStreamPlayer.new()
	music_player.name = "MenuMusic"
	music_player.volume_db = MUSIC_VOLUME

	if AudioServer.get_bus_index("Music") != -1:
		music_player.bus = "Music"
	else:
		music_player.bus = "Master"

	# Enable looping
	var looping_music = MAIN_THEME.duplicate() as AudioStreamWAV

	if looping_music != null:
		looping_music.loop_mode = AudioStreamWAV.LOOP_FORWARD
		looping_music.loop_begin = 0
		looping_music.loop_end = roundi(
			looping_music.get_length() * looping_music.mix_rate
		)
		music_player.stream = looping_music
	else:
		music_player.stream = MAIN_THEME

	add_child(music_player)

	# Create hover sound player
	hover_player = AudioStreamPlayer.new()
	hover_player.name = "MenuHover"
	hover_player.stream = HOVER_SOUND
	hover_player.volume_db = HOVER_VOLUME

	if AudioServer.get_bus_index("SFX") != -1:
		hover_player.bus = "SFX"
	else:
		hover_player.bus = "Master"

	add_child(hover_player)

	# Create selection sound player
	select_player = AudioStreamPlayer.new()
	select_player.name = "MenuSelect"
	select_player.stream = SELECT_SOUND
	select_player.volume_db = SELECT_VOLUME

	if AudioServer.get_bus_index("SFX") != -1:
		select_player.bus = "SFX"
	else:
		select_player.bus = "Master"

	add_child(select_player)

	# Detect scene changes
	get_tree().scene_changed.connect(_on_scene_changed)

	# Check the starting scene
	call_deferred("_on_scene_changed")


func _process(_delta: float) -> void:
	# Detect when a new scene instance loads
	var scene = get_tree().current_scene

	if scene == null:
		return

	if scene.get_instance_id() != current_scene_id:
		_on_scene_changed()


func _on_scene_changed() -> void:
	# The scene_changed signal does not pass arguments
	var scene = get_tree().current_scene

	if scene == null:
		return

	current_scene_id = scene.get_instance_id()

	var scene_name = scene.scene_file_path.get_file()

	menu_active = scene_name in MENU_SCENES

	if menu_active:
		# Keep music playing across menu scenes
		if not music_player.playing:
			music_player.play()

		# Connect sounds to buttons in the new scene
		_connect_menu_buttons(scene)

		print("Menu audio connected: ", scene_name)

	else:
		# Stop menu music outside menu scenes
		if music_player.playing:
			music_player.stop()


func _connect_menu_buttons(node: Node) -> void:
	if node is BaseButton:
		var button: BaseButton = node

		# Hover sound
		var hover_callback = _play_hover.bind(button)

		if not button.mouse_entered.is_connected(hover_callback):
			button.mouse_entered.connect(hover_callback)

		# Click sound
		if not button.button_down.is_connected(_play_select):
			button.button_down.connect(_play_select)

	# Include buttons inside containers
	for child in node.get_children():
		_connect_menu_buttons(child)


func _play_hover(button: BaseButton) -> void:
	if not menu_active:
		return

	if button.disabled:
		return

	hover_player.stop()
	hover_player.play()


func _play_select() -> void:
	if not menu_active:
		return

	select_player.stop()
	select_player.play()
